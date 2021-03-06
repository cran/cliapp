
#' @importFrom glue glue glue_collapse

inline_list <- NULL

#' @importFrom utils globalVariables

if (getRversion() >= "2.15.1") globalVariables(c("self", "private"))

inline_generic <- function(self, private, class, x) {
  id <- clii__container_start(self, private, "span", class = class)
  on.exit(clii__container_end(self, private, id), add = TRUE)
  style <- private$get_style()
  xx <- paste0(style$before$content, x, style$after$content)
  if (!is.null(style$main$fmt)) xx <- style$main$fmt(xx)
  xx
}

inline_transformer <- function(code, envir) {
  res <- tryCatch({
    expr <- parse(text = code, keep.source = FALSE)
    eval(expr, envir = envir)
  }, error = function(e) e)
  if (!inherits(res, "error")) return(res)

  code <- glue_collapse(code, "\n")
  m <- regexpr("(?s)^([[:alnum:]_]+)[[:space:]]+(.+)", code, perl = TRUE)
  has_match <- m != -1
  if (!has_match) stop(res)

  starts <- attr(m, "capture.start")
  ends <- starts + attr(m, "capture.length") - 1L
  captures <- substring(code, starts, ends)
  funname <- captures[[1]]
  text <- captures[[2]]

  out <- glue(text, .envir = envir, .transformer = inline_transformer)
  inline_generic(self, private, funname, out)
}

cmd_transformer <- function(code, envir) {
  res <- tryCatch({
    expr <- parse(text = code, keep.source = FALSE)
    eval(expr, envir = envir)
  }, error = function(e) e)
  if (!inherits(res, "error")) return(res)

  code <- glue_collapse(code, "\n")
  m <- regexpr("(?s)^([[:alnum:]_]+)[[:space:]]+(.+)", code, perl = TRUE)
  has_match <- m != -1
  if (!has_match) stop(res)

  starts <- attr(m, "capture.start")
  ends <- starts + attr(m, "capture.length") - 1L
  captures <- substring(code, starts, ends)
  funname <- captures[[1]]
  text <- captures[[2]]

  out <- glue(text, .envir = envir, .transformer = cmd_transformer)
  paste0("{", funname, " ", out, "}")
}

glue_cmd <- function(..., .envir) {
  ## This makes a copy that can refer to self and private
  str <- unlist(list(...), use.names = FALSE)
  environment(cmd_transformer) <- environment()
  args <- c(str, list(.envir = .envir, .transformer = cmd_transformer))
  do.call(glue, args)
}

clii__inline <- function(self, private, ..., .list) {
  ## This makes a copy that can refer to self and private
  environment(inline_transformer) <- environment()
  args <- c(list(...), .list, list(.transformer = inline_transformer))
  do.call(glue, args)
}
