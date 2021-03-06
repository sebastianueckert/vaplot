test_that("calculation of the RUV variability works for a linearized model", {
  deps <- matrix(c(1,1,1,1, 0.1, 0.2, 0.3, 0.4), 4, 2)
  sigma <- diag(c(1, 0.05), 2, 2)
  omega <- diag(1, 1)
  depsdeta <- matrix(0, 4, 2)

  expect_equal(var_ruv_lf(deps, depsdeta, omega, sigma), diag(deps %*% sigma %*% t(deps))) # assuming no interaction

})


test_that("calculation of total variability from variables works for a linearized model",{
  deta <- matrix(1,1,2, dimnames = list(NULL, c("eta1", "eta2")))
  omega <- set_rcnames(diag(c(1, 2), 2, 2), c("eta1", "eta2"))
  omega2 <- omega
  omega2[1,2] <- omega2[2,1] <- 0.5
  expect_equal(var_iiv_from_lf(deta, omega, c("eta1", "eta2")), 3)
  expect_equal(var_iiv_from_lf(deta, omega, c("eta2")), 2)
  expect_equal(var_iiv_from_lf(deta, omega2, c("eta1", "eta2")), 1+2+2*0.5)
})

test_that("calculation of total variability conditional on variables works for a linearized model",{
  deta <- matrix(1,1,2, dimnames = list(NULL, c("eta1", "eta2")))
  omega <- set_rcnames(diag(c(1, 2), 2, 2), c("eta1", "eta2"))
  omega2 <- omega
  omega2[1,2] <- omega2[2,1] <- 0.5
  expect_equal(var_iiv_cond_lf(deta, omega, c("eta2")), 1)
  expect_equal(var_iiv_cond_lf(deta, omega, c("eta1", "eta2")), 0)
  expect_equal(var_iiv_cond_lf(deta, omega2, "eta1"), 1.75)
})

test_that("calculation of variability from var conditional on var works for lin mod",{
  deta <- matrix(1,1,2, dimnames = list(NULL, c("eta1", "eta2")))
  omega <- set_rcnames(diag(c(1, 2), 2, 2), c("eta1", "eta2"))
  omega2 <- omega
  omega2[1,2] <- omega2[2,1] <- 0.5
  expect_equal(var_iiv_from_cond_lf(deta, omega, vars = c("eta2", "eta1"), cond_on = c()), 3)
  expect_equal(var_iiv_from_cond_lf(deta, omega, vars = c("eta1"), cond_on = c("eta2")), 1)
  expect_equal(var_iiv_from_cond_lf(deta, omega2, vars = "eta1", cond_on = "eta2"), 0.875)
})

test_that("calculation of variability from var conditional on var works for lin mod with degenerate omega",{
  deta <- matrix(1,1,3, dimnames = list(NULL, c("eta1", "eta2", "eta3")))
  omega <- set_rcnames(diag(c(1, 2, 0), 3, 3), c("eta1", "eta2", "eta3"))
  omega2 <- omega
  omega2[1,2] <- omega2[2,1] <- 0.5
  expect_equal(var_iiv_from_cond_lf(deta, omega, vars = c("eta2", "eta1", "eta3"), cond_on = c()), 3)
  expect_equal(var_iiv_from_cond_lf(deta, omega, vars = c("eta1"), cond_on = c("eta2")), 1)
  expect_equal(var_iiv_from_cond_lf(deta, omega2, vars = "eta1", cond_on = c("eta2", "eta3")), 0.875)
  expect_equal(var_iiv_from_cond_lf(deta, omega2, vars = c("eta1","eta2"), cond_on = "eta3"), 4)
})

test_that("conditioning arguments are generated correctly", {
  expect_equal(gen_cond_args(paste0("eta", 1:2)),
               list(list(vars = "eta1", cond_on = NULL), list(vars = "eta2", cond_on = "eta1")))
})
