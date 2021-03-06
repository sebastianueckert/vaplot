#' Read results from a NM run
#'
#' @param lst_file Path to a NONMEM results file
#' @param problem Number of the $PROBLEM to use
#' @param column_specs Column specifications as produced by nm_column_specs()
#' @param column_mappers Derivative to variable mapping specification as produced by nm_column_mappers()
#' @param ignore_expr Expression defining which rows from the table to ignore (evaluated in the context of
#' the table). The default is to ignore EVID!=0.
#'
#' @export
prepare_va_nm <- function(lst_file, problem = NULL,
                          column_specs = nm_column_specs(),
                          column_mappers = nm_column_mappers(), ignore_expr){

  ignore_expr <- rlang::enquo(ignore_expr)
  # ignore nothing if ignore_expr is set to NULL
  if(rlang::quo_is_null(ignore_expr)) ignore_expr <- rlang::quo(FALSE)

  if(!requireNamespace("xpose", quietly = TRUE))
    ui_error("The 'xpose' package could not be loaded but is required to read NONMEM results",
             suggestions = c("Install 'xpose' using: install.packages('xpose')"))


  xpdb <- xpose::xpose_data(file = lst_file, simtab = FALSE, extra_files = c('.ext'), quiet = TRUE)

  # read & prepare estimates
  estimates <- get_estimates(xpdb, problem)

  neta <- NCOL(estimates$omega)
  neps <- NCOL(estimates$sigma)
  eta_names <- glue::glue("ETA{i}", i = seq_len(neta))
  eps_names <- glue::glue("EPS{i}", i = seq_len(neps))

  # prepare table data
  tab <- get_table_data(xpdb,  problem = problem)
  tab_split <- split_table_data(tab,
                          ignore_expr = ignore_expr,
                          column_specs = column_specs,
                          column_mappers = column_mappers,
                          eta_names = eta_names,
                          eps_names = eps_names)

  omega <- estimates$omega
  sigma <- estimates$sigma
  rownames(omega) <- colnames(omega) <- eta_names
  rownames(sigma) <- colnames(sigma) <- eps_names

  inp <- va_input(
    column_names = colnames(tab_split[[1]][["other"]]),
    theta = estimates$theta,
    omega = omega,
    sigma = sigma,
    derivative_data = tab_split,
    input_file = lst_file,
    variable_names = eta_names
  )

  return(inp)
}

split_table_data <- function(tab, ignore_expr, column_specs, column_mappers, eta_names, eps_names){
  column_names <- colnames(tab)

  # default ignore when argument is not provided
  if(missing(ignore_expr)|| rlang::quo_is_missing(ignore_expr)){
    ignore_expr <- rlang::quo(FALSE)
    if("EVID" %in% column_names) ignore_expr <- rlang::quo(EVID!=0)
    if("MDV" %in% column_names) ignore_expr <- rlang::quo(MDV!=0)
    if(all(c("MDV", "EVID") %in% column_names)) ignore_expr <- rlang::quo(EVID!=0|MDV!=0)
  }
  tab <- dplyr::filter(tab, !(!!ignore_expr))

  # try column selection in safe manner
  selection_results <- purrr::map(column_specs, purrr::safely(~tidyselect::vars_select(colnames(tab), !!.x)))
  # collect selection errors
  selection_errors <- selection_results %>%
    purrr::map("error") %>%
    purrr::compact()

  if(length(selection_errors) != 0) {
    failed_columns <- names(selection_errors) %>% paste(collapse = ",")
    ui_error(paste("Could not find the required column(s):", failed_columns),
             suggestions = c("Check the supplied column_specs argument",
                             "In NONMEM, check the $TABLE statement for missing columns",
                             "Verify the generated table file"))
  }

  # selection results
  column_groups <- selection_results %>%
    purrr::map("result")

  # all remaining columns
  other_columns <- column_names[!column_names %in% unlist(column_groups)]
  column_groups[["other"]] <- other_columns

  id_column <- tab[[column_groups[["id"]]]]

  # split by ID and extract column groups
  res <- split(tab, id_column, drop = TRUE) %>%
    purrr::map(function(df) purrr::imap(column_groups,
                                        ~select_rows(.x, .y, df, mappers = column_mappers,
                                                     eta_names = eta_names, eps_names = eps_names)))

}

select_rows <- function(cols, group, df, mappers,  eta_names, eps_names) {
  if(group == "id"){
    df[1, cols, drop = TRUE]
  }else if(group == "eta"){
    #data.matrix(df[1, cols, drop = FALSE]) %>% t()
  }else if(group == "deta"){
    m <- data.matrix(df[, cols, drop = FALSE])
    # rename columns to match ETAs
    eta_indicies <- mappers$deta_mapper(colnames(m))
    colnames(m) <- eta_names
    return(m)
  }else if(group == "deps"){
    m <- data.matrix(df[, cols, drop = FALSE])
    # rename columns to match ETAs
    eps_indicies <- mappers$deps_mapper(colnames(m))
    colnames(m) <- eps_names
    return(m)
  }else if(group == "deps_deta"){
    data.matrix(df[,cols, drop = FALSE])
  }else{
    df[,cols,drop=FALSE]
  }
}

get_estimates <- function(xpdb, problem){
  theta <- get_theta_vector(xpdb, problem = problem)
  omega <- get_omega_matrix(xpdb, problem = problem)
  sigma <- get_sigma_matrix(xpdb, problem = problem)
  return(list(theta=theta, omega=omega, sigma=sigma))
}

get_table_data <- function(xpdb, problem = NULL){
  xpose::get_data(xpdb, .problem = problem, quiet = TRUE)
}

get_theta_vector <- function(xpdb, problem = NULL, subprob = NULL,
                             method = NULL) {
  xpose::get_file(xpdb, ext = "ext", .problem = problem, .subprob = subprob, .method = method, quiet = T) %>%
    dplyr::filter(ITERATION == -1000000000) %>%
    dplyr::select(dplyr::starts_with("THETA")) %>%
    unlist()
}

get_omega_matrix <- function(xpdb, problem = NULL, subprob = NULL,
                             method = NULL){
  xpose::get_file(xpdb, ext = "ext", .problem = problem, .subprob = subprob, .method = method, quiet = T) %>%
    dplyr::filter(ITERATION==-1000000000) %>%
    dplyr::select(dplyr::starts_with("OMEGA")) %>% unlist() %>%
    lower_tri_vec_to_mat()
}

get_sigma_matrix <- function(xpdb, problem = NULL, subprob = NULL,
                             method = NULL){
  xpose::get_file(xpdb, ext = "ext", .problem = problem, .subprob = subprob, .method = method, quiet = T) %>%
    dplyr::filter(ITERATION==-1000000000) %>%
    dplyr::select(dplyr::starts_with("SIGMA")) %>% unlist() %>%
    lower_tri_vec_to_mat()
}

