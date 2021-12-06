# Introduction

## Specification error in linear regression

Linear regression model is one of the fundamental statistical models of analyzing the relationship between a pair of variables $Y$ and $\boldsymbol{X}$. Under the classical settings, given a linear regression in the form,

$$\boldsymbol{Y} = \boldsymbol{X}\boldsymbol{\beta} + \boldsymbol{\varepsilon}.$$


Five assumptions will be assumed to satisfy:

1. $\mathbb{E}[\boldsymbol{\varepsilon}|\boldsymbol{X}] = \boldsymbol{0}$
2. $\mathbb{E}[\boldsymbol{\varepsilon}\boldsymbol{\varepsilon}'|\boldsymbol{X}] = \sigma^2\boldsymbol{I}$
3. $\mathbb{E}[\boldsymbol{X}'\boldsymbol{\varepsilon}|\boldsymbol{X}] = \boldsymbol{0}$
4. $\boldsymbol{\varepsilon}|\boldsymbol{X} \sim N(\boldsymbol{0},\sigma^2\boldsymbol{I})$
5. $\boldsymbol{X}'\boldsymbol{X}$ is positive definite.

Specification error occurs when at least one of the assumptions is violated. Efforts usually needs to made to check the validation of the assumptions if we would like to believe the derived statistical properties of the linear regression followed by the presumed underlying data generating process, rather than treat the linear regression as a predictive model which tries its best to approximate the true relationship between $Y$ and $\boldsymbol{X}$ with a straight line.

## Visual inference

As an alternative to conventional statistical tests, like F-test and Chow test, graphical devices for model diagnostic have been developed for years due to their ease of detecting recognizable violations of the assumptions, while providing the examiner with an opportunity to explore the fitted model in different views. 

Unlike the conventional statistical tests, which is a deterministic procedure if the data and the significance level are given, the interpretation of the graphical devices will naturally and unavoidably vary from one observer to another, that is,  the probability of the decision made by two observers are the same is not equal to one. This leads to potential over or under interpretation of the visual discoveries. 

Visual inference is a class of hypothesis tests which introduces statistical inference for exploratory data analysis. It adopts graphic representation of data as the test statistic and relies on human evaluations of the test statistic to decide whether or not the null hypothesis should be rejected. This type of inference provides a method to statistically test visual discoveries, which helps calibrate the discovery process. Tough it will still suffer from individual effects, remedies can usually made by involving multiple individuals in a testing procedure. 

## Residual plot

Among all the regression graphics, residual plot, or more specifically, residual versus fitted value plot is commonly used in examining the homoscedasticity and linearity assumptions put on the stochastic error term and the model. 

### Theoretical results

Given the fitted linear regression model is

$$\boldsymbol{Y} = \boldsymbol{X}\boldsymbol{b} + \boldsymbol{e},$$

where $\boldsymbol{b} = (\boldsymbol{X}'\boldsymbol{X})^{-1}\boldsymbol{X}'\boldsymbol{Y}$ and $\boldsymbol{e} = \boldsymbol{Y} - \boldsymbol{Xb}$.

::: {.rmdnote}

::: {.proposition name="Distribution of OLS residuals"}
Under the null hypothesis that the linear regression model is correctly specified, the residuals $\boldsymbol{e}$ follow a null distribution

$$\boldsymbol{e} \sim N(\boldsymbol{0},\boldsymbol{R}\sigma^2),$$
where $\boldsymbol{R} = \boldsymbol{I} - \boldsymbol{X}(\boldsymbol{X}'\boldsymbol{X})^{-1}\boldsymbol{X}'$.
:::

::: {.proof}
By the definition of the residuals $\boldsymbol{e}$,

\begin{align*}
\boldsymbol{e} &= \boldsymbol{Y} - \boldsymbol{Xb}\\
&= \boldsymbol{Y} - \boldsymbol{X}(\boldsymbol{X}'\boldsymbol{X})^{-1}\boldsymbol{X}'\boldsymbol{Y}\\
&= (\boldsymbol{I} - \boldsymbol{X}(\boldsymbol{X}'\boldsymbol{X})^{-1}\boldsymbol{X}')\boldsymbol{Y}\\
&= \boldsymbol{R}\boldsymbol{Y}\\
&= \boldsymbol{R}(\boldsymbol{X}\boldsymbol{\beta} + \boldsymbol{\varepsilon})\\
&= (\boldsymbol{I} - \boldsymbol{X}(\boldsymbol{X}'\boldsymbol{X})^{-1}\boldsymbol{X}')\boldsymbol{X}\boldsymbol{\beta} + \boldsymbol{R}\boldsymbol{\varepsilon}\\
&= \boldsymbol{R}\boldsymbol{\varepsilon}.\\
\end{align*}

Since by assumption, $\boldsymbol{\varepsilon} \sim N(\boldsymbol{0},\sigma^2\boldsymbol{I})$, and because 

\begin{align*}
\boldsymbol{R}\boldsymbol{R}' &= (\boldsymbol{I} - \boldsymbol{X}(\boldsymbol{X}'\boldsymbol{X})^{-1}\boldsymbol{X}')(\boldsymbol{I} - \boldsymbol{X}(\boldsymbol{X}'\boldsymbol{X})^{-1}\boldsymbol{X}')' \\
&= \boldsymbol{I} -  \boldsymbol{X}(\boldsymbol{X}'\boldsymbol{X})^{-1}\boldsymbol{X}' \\
&= \boldsymbol{R}.
\end{align*}

Then, 
$$\boldsymbol{e} \sim N(\boldsymbol{0},\boldsymbol{R}\sigma^2).$$
$$\tag*{$\blacksquare$}$$
:::

:::


Clearly, under the null hypothesis, the residuals are heteroskedastic, since the matrix $\boldsymbol{R}$ is not an identity matrix. However, with large sample, the residuals $\boldsymbol{e} \approx \boldsymbol{\varepsilon}$. 

:::{.rmdnote}

:::{.proposition name="Consistency of OLS estimator"}
Suppose $$T^{-1}\boldsymbol{X}'\boldsymbol{X} \overset{p}{\longrightarrow}\boldsymbol{G}_{XX} \quad as ~n \longrightarrow \infty,$$ where $\boldsymbol{G}_{XX}$ is a positive definite matrix of finite elements. And $$T^{-1}\boldsymbol{X}'\boldsymbol{\varepsilon} \overset{p}{\longrightarrow}\boldsymbol{0} \quad as ~n \longrightarrow \infty.$$ Then the OLS estimator for $\boldsymbol{b}$ is consistent, that is $$\boldsymbol{b} \overset{p}{\longrightarrow}\boldsymbol{\beta} \quad as ~n \longrightarrow \infty.$$

:::

::: {.proof}
Given the OLS solution is 
\begin{align*}
\boldsymbol{b} &= (\boldsymbol{X}'\boldsymbol{X})^{-1}\boldsymbol{X}'\boldsymbol{Y} \\
&= (\boldsymbol{X}'\boldsymbol{X})^{-1}\boldsymbol{X}'(\boldsymbol{X}\boldsymbol{\beta} + \boldsymbol{\varepsilon}) \\
&= \boldsymbol{\beta} + (\boldsymbol{X}'\boldsymbol{X})^{-1}\boldsymbol{X}'\boldsymbol{\varepsilon}.
\end{align*}

Thus, by Slutsky's theorem the probability limit of $\boldsymbol{b}$ is

$$plim(\boldsymbol{b}) = plim(\boldsymbol{\beta}+ (\boldsymbol{X}'\boldsymbol{X})^{-1}\boldsymbol{X}'\boldsymbol{\varepsilon})=\boldsymbol{\beta}+\boldsymbol{G}_{XX}^{-1}\boldsymbol{0}=\boldsymbol{\beta}.$$

$$\tag*{$\blacksquare$}$$

:::

:::

This suggests, the difference between $\boldsymbol{b}$ and $\boldsymbol{\beta}$ is small in large sample size. Therefore, the difference between $\boldsymbol{e}$ and $\boldsymbol{\varepsilon}$ will also be small in large sample size, that is
$$\boldsymbol{\varepsilon}\overset{approx}{\sim} N(\boldsymbol{0},\sigma^2\boldsymbol{I}).$$

### Emprical use

TODO: how to interpret residual plot?
