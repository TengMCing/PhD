# Conclusion and future plans {#sec-conclusion}

The three pieces of work assembled in this thesis share a common theme of advancing regression diagnostics, with a focus on improving the assessment of residual plots, challenging the limitations of conventional methods, and developing innovative solutions to automate diagnostic processes.

## Contributions

The primary contributions of this research are threefold. Firstly, we provide empirical evidence for the effectiveness of the lineup protocol in diagnosing model fit issues through residual plots [@li2024plot]. Secondly, we develop computer vision model for automating the assessment of residual plots, which addresses the scalability limitations of lineup protocol. Lastly, we share a user-focused R package and Shiny app, making the automated diagnostic tools accessible to a broad range of analysts and practitioners. 

The aforementioned R package (and its dependency) is available on CRAN with the latest development versions in the links below:

- `autovi` (<https://github.com/TengMCing/autovi>), and
- `bandicoot` (<https://github.com/TengMCing/bandicoot>).


The Shiny app for `autovi` is available at one of the mirror sites listed at <https://autoviweb.netlify.app/> with the source code available at <https://github.com/TengMCing/autovi_web>.

Principles of transparency and reproducible research have guided the work with all materials related to the thesis at <https://github.com/TengMCing/PhD>.  The thesis is written using Quarto [@Allaire_Quarto_2024] and is available online at <https://patrick-li-thesis.netlify.app>.


## Future work

There are several directions that this work can be developed. These include improving the accuracy and effectiveness of residual plot assessments, exploring the use of alternative computer vision models, extending the automated visual diagnostics to different plot types and statistical models, and improving the front-end display and back-end computation for the web app.

The model in @sec-third-paper, trained on standard residual plots from linear regression, has certain limitations. It was very difficult to arrive at a final model to share, with the main concern is that the current version may still be too sensitive, leading to a decision that the model is misspecified even when problems are minor. While the current implementation relies on the basic VGG16 model [@simonyan2014very], developed a decade ago, performance could be enhanced by exploring more advanced versions like ResNet50 [@he2016deep] and DenseNet201 [@huang2017densely], as well as ensemble techniques. There is room to improve the accuracy and effectiveness of residual plot assessments.

Residual plots from more complex models, such as hierarchical, temporal, or spatial regression, often exhibit distinct visual patterns that the current approach might not fully capture. To better address this, using scaled residual plots, with randomized quantile residuals [@dunn1996randomized], offers a more flexible approach for defining residuals across different regression models, though it may alter the original visual pattern. Building a computer vision model on this foundation can provide a stronger solution for assessing residual plots across a broader spectrum of regression models. 

Visual diagnostics are foundational in Bayesian modelling to assess model fit, convergence, and posterior distributions (see @gelman2013). Some common visual diagnostics include trace plots to assess convergence of Markov Chain Monte Carlo (MCMC) chains, density plots to visualize posterior distributions, posterior predictive checks to assess model fit, and autocorrelation plots to assess dependence between samples in MCMC chains. These visual diagnostics help Bayesian modelers to evaluate the quality of their models and identify potential issues or areas for improvement. Automating the reading of these plots can help improve MCMC convergence diagnostics, facilitate model comparison and selection, and enhance uncertainty quantification.

The development of a more comprehensive suite of automated visual diagnostics for statistical models can help to improve the quality of statistical analyses. Also important is the development of user-friendly interfaces for these diagnostics, such as web applications, to make them accessible to a wider audience of researchers and practitioners. The web app developed in this thesis is a step in this direction, but further work is needed to improve the user experience, add more features, and make the app more robust and scalable. Future work could also explore the use of interactive visualizations and dashboards to help users explore and interpret the results of automated visual diagnostics more effectively.
