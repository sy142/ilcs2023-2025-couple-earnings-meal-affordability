suppressPackageStartupMessages({library(brms); library(cmdstanr)})
set.seed(1)
d <- data.frame(y = rbinom(2000, 1, 0.3), x = rnorm(2000))
f <- tryCatch(brm(y ~ x, data = d, family = bernoulli(), backend = "cmdstanr", opencl = opencl(c(0, 0)), chains = 1, iter = 200, refresh = 0, silent = 0),
              error = function(e) { cat("HATA:", conditionMessage(e), "\n"); NULL })
if (!is.null(f)) print(summary(f))
