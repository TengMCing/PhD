# Conclusion and future plans {#sec-conclusion}

The three pieces of work assembled in this thesis share a common theme of advancing regression diagnostics, with a focus on improving the assessment of residual plots, challenging the limitations of conventional methods, and developing innovative solutions to automate diagnostic processes.

## Contributions

The primary contributions of this research are threefold. Firstly, we provide empirical evidence for the effectiveness of lineup protocol in diagnosing model fit issues through residual plots. Secondly, we develop computer vision model for automating the assessment of residual plots, which addresses the scailaibty limitations of lineup protocol. Lastly, we introduce a user-friendly R package and Shiny app, making the automated diagnostic tools accessible to a broad range of analysts and practitioners.


Principles of transparency and reproducible research have guided the work. The materials to reproduce this thesis are available at [`github.com/TengMCing/PhD/Thesis`](https://github.com/TengMCing/PhD/Thesis) and software packages are:

- software 1
- software 2

...

This work is licensed under a [Creative Commons  Attribution-NonCommercial-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-nc-sa/4.0/).

## Future work

There are several directions that this work can be developed: alternative computer vision models, and extensions to different types of visual diagnostics. 

The model in Chapter 3, trained on standard residual plots from linear regression, has certain limitations. Residual plots from more complex models, such as hierarchical, temporal, or spatial regression, often exhibit distinct visual patterns that the current approach might not fully capture. To better address this, using scaled residual plots with randomized quantile residuals [@dunn1996randomized] offers a more flexible approach for defining residuals across different regression models, though it may alter the original visual pattern. Building a computer vision model on this foundation can provide a stronger solution for assessing residual plots across a broader spectrum of regression models. While the current implementation relies on the basic VGG16 model [@simonyan2014very], developed a decade ago, performance could be enhanced by exploring more advanced models like ResNet50 [@he2016deep] and DenseNet201 [@huang2017densely], as well as ensemble techniques, to improve the accuracy and effectiveness of residual plot assessments.

Visual diagnostics are also common in Bayesian modelling to assess model fit, convergence, and posterior distributions. Some common visual diagnostics used in Bayesian modelling include trace plots to assess convergence of Markov Chain Monte Carlo (MCMC) chains, density plots to visualize posterior distributions, posterior predictive checks to assess model fit, and autocorrelation plots to assess dependence between samples in MCMC chains. These visual diagnostics help Bayesian modelers to evaluate the quality of their models and identify potential issues or areas for improvement. Automating the reading of these plots can help improve MCMC convergence diagnostics, facilitate model comparison and selection, and enhance uncertainty quantification.
