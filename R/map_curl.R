#' Fetch and process data from multiple URLs asyncronously
#'
#' Uses the [*curl* package's async API][curl::multi()] to fetch data from
#' multiple URLs asyncronously, processing them through a *purrr*-style
#' functional if needed.  Timeout, retry, delay, and handle options provide
#' tools to support politely but efficiently fetching data from slow,
#' unreliable, underpowered sites.
#'
#' @param urls a character vector or URLs to scrape.  If names, the return
#' @param .f A function or purrr-style lambda to process return values with. Its
#'   first argument, a [curl::curl_fetch_memory()] response.
#' @param ... further arguments passed to .f
#' @param .logfile If not NULL, a file to write messages to. Messages are
#'   appended.
#' @param .verbose Whether to write messages to the console
#' @param .files A character vector of filenames the same length as `urls`, to
#'   write the content of responses to.
#' @param .total_con Total number of connections allowed at the same time
#' @param .host_con Connections allowed to a single host at the same time
#' @param .timeout Timeout for the whole process
#' @param .delay Either a number in seconds or a zero-argument function that
#'   generates a single number.
#' @param .handle_opts a list of options passed [curl::handle_setopt()]. Can be
#'   a list of lists the same length as `urls`.
#' @param .handle_headers  a list of options passed [curl::handle_setheaders()]
#'   Can be a list of lists the same length as `urls`.
#' @param .handle_form  a list of options passed [curl::handle_setform()] Can be
#'   a list of lists the same length as `urls`.
#' @param .retry  Number of times to retry any URL that fails
#' @param x an object of class `map_curl`, returned by `map_curl()`
#' @return A list of responses of class `map_curl`.  Failed responses will be
#'   `NULL` values. Names will be the URLs unless `urls` was a named vector, in
#'   which case its names will be used. The number of attempts made on each URL
#'   can be retrieved by calling `attempts()` on the result.
#' @export
#' @import curl
map_curl <-
  function(urls, .f = identity, ..., .logfile = NULL, .verbose = TRUE, .files = NULL,
           .total_con = 100L, .host_con = 6L, .timeout = Inf, .delay = 0,
           .handle_opts = list(low_speed_limit = 100, low_speed_time = 30),
           .handle_headers = NULL, .handle_form = NULL, .retry = 0) {

    out <- structure(vector("list", length(urls)), .Names = urls)
    attempts <- structure(rep(0, length(urls)), .Names = urls)
    .f <- purrr::as_mapper(.f)
    if (is.numeric(.delay)) {
      delay_fn <- function() Sys.sleep(.delay)
    } else {
      .delay <- rlang::as_function(.delay)
      delay_fn <- function() Sys.sleep(.delay())
    }
    if (!is.null(.files)) {
      stopifnot(length(urls) == length(.files))
      names(.files) <- urls
    }

    make_handle <- function(i) {
      h <- new_handle(url = urls[i])
      if (!is.null(.handle_opts)) {
        if (inherits(.handle_opts[[1]], "list"))
          h <- handle_setform(h, .list = .handle_opts[[i]])
        else
          h <- handle_setopt(h, .list = .handle_opts)
      }
      if (!is.null(.handle_headers)) {
        if (inherits(.handle_headers[[1]], "list"))
          h <- handle_setform(h, .list = .handle_headers[[i]])
        else
          h <- handle_setheaders(h, .list = .handle_headers)
      }
      if (!is.null(.handle_form)) {
        if (inherits(.handle_form[[1]], "list"))
          h <- handle_setform(h, .list = .handle_form[[i]])
        else
          h <- handle_setform(h, .list = .handle_form)
      }
      return(h)
    }

    map_pool <- new_pool(total_con = .total_con, host_con = .host_con)

    done_fn <- function(resp) {
      if (!is.null(.files)) {
        con <- file(.files[resp$url], "wb")
        writeBin(resp$content, con)
        close.connection(con)
      }
      out[[resp$url]] <<- .f(resp, ...)
      attempts[[resp$url]] <<- attempts[[resp$url]] + 1

      if (.verbose) message(format(Sys.time()), " - Fetched: ", resp$url)
      if (!is.null(.logfile)) {
        cat(format(Sys.time()), "- Fetched:", resp$url, "\n", file = .logfile, append = TRUE)
      }

      delay_fn()
    }

    fail_fn <- function(err, i) {
      if (.verbose) message(format(Sys.time()), " - Failed:  ", urls[i], ", ", err)
      if (!is.null(.logfile)) {
        cat(format(Sys.time()), "- Failed: ", urls[i], ",", err, "\n", file = .logfile, append = TRUE)
      }
      attempts[[urls[i]]] <<- attempts[[urls[i]]] + 1
      if (attempts[[urls[i]]] <= .retry)
        multi_add(make_handle(i), done = done_fn, pool = map_pool,
                  fail = function(err) fail_fn(err, i))
      delay_fn()
    }

    for (i in seq_along(urls)) {
      fail_closure <- function(err) {
        ival <- i
        function(err) fail_fn(err, ival)
      }
      multi_add(make_handle(i), done = done_fn, fail = fail_closure(),
                pool = map_pool)
    }

    multi_run(timeout = Inf, poll = FALSE, pool = map_pool)

    if (!is.null(names(urls))) {
      names(out) <- names(urls)
      names(attempts) <- names(attempts)
    }
    attr(out, "attempts") <- attempts
    class(out) <- "map_curl"
    return(out)
  }

#' @rdname map_curl
#' @export
attempts <- function(x) {
  UseMethod("attempts", x)
}

attempts.map_curl <- function(x) {
  attr(x, "attempts")
}

#' @export
print.map_curl <- function(x, ...) {
  att <- attr(x, "attempts")
  attr(x, "attempts") <- NULL
  print.default(x, ...)
  cat(sum(att), "attempts on", length(att), "URLs")

}
