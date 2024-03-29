# This script provides a demonstration of some tools that can be used to conduct a reliability analysis in R.

###################################################

# 1. Load required packages, functions and datasets.

# anything to the right of a hash is a comment / commented-out code.

# setwd("path to where these files are stored")
install.packages("SPREDA", dependencies = TRUE)
install.packages("boot", dependencies = TRUE)
install.packages("lattice", dependencies = TRUE)

library(SPREDA)
library(boot)
library(lattice)
source("https://raw.githubusercontent.com/CodeOwl94/ross-reliability/master/ReliabilitySupportFns.R")
exa1 <- read.csv("test2.csv",
                 header = T)

dim(exa1)
head(exa1) # returns the first 6 rows:
stack(table(exa1$fail))
exa1$fail <- ifelse(exa1$fail == "S", "T", as.character(exa1$fail))
exa1.dat <- data.frame(time = exa1$time,
                       event = 1 - as.numeric(as.logical(exa1$fail)))
stack(table(exa1.dat$event))
str(exa1.dat)
head(exa1.dat)

# 2. Graphical analysis.


Probability.Plots(exa1.dat, dist = "Weibull")
title("Figure 1", adj = 1)

# 3. Fit models and estimate parameters.

exa1.spreda <- Lifedata.MLE(Surv(time, event) ~ 1,
                            data = exa1.dat,
                            dist = "weibull")
summary(exa1.spreda)
(beta.spreda <- 1 / unname(exp(exa1.spreda$coef[2])))
(eta.spreda <- unname(exp(exa1.spreda$coef[1])))
beta.95cl_hi <- 1 / (summary(exa1.spreda)$coefmat["sigma", "95% Lower"])
beta.95cl_lo <- 1 / (summary(exa1.spreda)$coefmat["sigma", "95% Upper"])
eta.95cl_lo <- exp(summary(exa1.spreda)$coefmat["(Intercept)", "95% Lower"])
eta.95cl_hi <- exp(summary(exa1.spreda)$coefmat["(Intercept)", "95% Upper"])
(beta.ests <- c(lower = beta.95cl_lo, est = beta.spreda, upper = beta.95cl_hi))
(eta.ests <- c(lower = eta.95cl_lo, est = eta.spreda, upper = eta.95cl_hi))
Probability.Plots(exa1.dat, dist = "Weibull")
# Get transformed time (x axis) and Fhat (y axis) values: 
Weibull.xval <- log(Calculate.Fhat(exa1.dat)$time) # <---- THIS IS WHAT I BELIEVE NEEDS WORK
exa1.Fhat <- Calculate.Fhat(exa1.dat)$Fhat
Weibull.yval <- log(-log(1 - exa1.Fhat))
# Get intercept and slope of mle fit on linear scale:
Weibull.slope <- 1 / beta.spreda
Weibull.intercept <- log(eta.spreda)
# Plot as a red coloured line:
lines(x = Weibull.slope * Weibull.yval + Weibull.intercept,
      y = Weibull.yval,
      col = 'red', lwd = 2)
title("Figure 2", adj = 1)
Weibull.Confidence.Region(data = exa1.dat,
                          model = exa1.spreda,
                          probability = 0.95,
                          show.contour.labels = "TRUE",
                          title = "Figure 9")

# 4. Inference.

hazard.plot.w2p(beta = beta.spreda, eta = eta.spreda, time = exa1.dat$time, line.colour = "blue")
title("Figure 3", adj = 1)
Reliability.plot.w2p(beta = beta.spreda, eta = eta.spreda, time = exa1.dat$time, line.colour = "blue")
# Then add a vertical line at t=30 to this plot:
abline(v = 30, col = "lightgray", lty = 2)
title("Figure 4", adj = 1)
Calc.Unreliability.w2p(beta = beta.spreda, eta = eta.spreda, time = 30)
(Rel.30 <- round(1 - Calc.Unreliability.w2p(beta = beta.spreda, eta = eta.spreda, time = 30), 3))
Calc.Warranty.w2p(beta = beta.spreda, eta = eta.spreda, R = Rel.30)
(MTTF.exa1 <- Weibull.2p.Expectation(eta = eta.spreda, beta = beta.spreda))
################################################
# Bootstrapping section: this section takes about 10-15 mins to run.
set.seed(123)
(aa <- Sys.time())
MTTF.boot.95CI.bca <- boot(data = exa1.dat,
                           statistic = MTTF.boot.percentile.adj,
                           R = 10000)
MTTF.boot.95CI.bca
(MTTF.boots.bca <- boot.ci(MTTF.boot.95CI.bca, conf = 0.95, type = "bca"))
bb <- Sys.time()
(Time.taken <- bb - aa)

################################################
MTTF.95cl_lo <- MTTF.boots.bca$bca[length(MTTF.boots.bca$bca) - 1]
MTTF.95cl_hi <- MTTF.boots.bca$bca[length(MTTF.boots.bca$bca)]
(MTTF.ests <- c(lower = MTTF.95cl_lo, est = MTTF.exa1, upper = MTTF.95cl_hi))
mean(exa1.dat[exa1.dat$event == 1, "time"])
xfit <- seq(0, max(exa1.dat$time), by = 0.01)
mle.pdf <- dweibull(xfit, shape = beta.spreda,
                    scale = eta.spreda)
plot(xfit, mle.pdf, type = 'l', col = 'red',
     xlab = "Time To Failure", ylab = "f(t)",
     ylim = c(0, 1.25 * max(mle.pdf)), bty = 'l',
     las = 1, adj = 0.5, cex.lab = 1.2, cex.axis = 0.85)

lines(rep(MTTF.exa1, 2), c(0, dweibull(MTTF.exa1,
                                    shape = beta.spreda, scale = eta.spreda)),
      lwd = 2, col = 'red')
lines(rep(MTTF.95cl_lo, 2), c(0, dweibull(MTTF.95cl_lo,
                                       shape = beta.spreda, scale = eta.spreda)), lty = 2,
      lwd = 2, col = 'red')
lines(rep(MTTF.95cl_hi, 2), c(0, dweibull(MTTF.95cl_hi,
                                       shape = beta.spreda, scale = eta.spreda)), lty = 2,
      lwd = 2, col = 'red')
title("Figure 5", adj = 1)

###