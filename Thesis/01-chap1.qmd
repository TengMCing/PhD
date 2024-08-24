# Introduction {#sec-intro}

Model diagnostics play a critical role in evaluating the accuracy and validity of a statistical model. They enable the assessment of the model’s assumptions, detection of outliers, evaluation of how well the model fits the data, and identification of possible approaches to improve the model’s performance. 

When conducting model diagnostics, graphical representations of data are often preferred or required by data analysts. The preference for visual diagnostics is attributed to its intuitive nature and the possibility of discovering unexpected abstract and unquantifiable insights. In the context of regression diagnostics, a common practice is to plot residuals against fitted values, which serves as a starting point for evaluating the adequacy of the fit and verifying the underlying assumptions. 

Recently, a novel statistical inferential framework known as visual inference [@buja2009statistical] has been developed, which relies on the use of graphical representations of data. The visual inference approach makes use of the natural capability of the human visual system to identify patterns and deviations from expected patterns. It provides a more comprehensible way of interpreting data and conducting hypothesis testing compared to conventional statistical testing.

Practically, visual inference is conducted via the lineup protocol. The protocol is inspired by the police lineup technique employed in eyewitness identification of criminal suspects. It comprises $m$ randomly positioned plots, where one of them represents the data plot, while the remaining $m-1$ plots represent the null plots with the same graphical structure, except that the data has been replaced with data consistent with the null hypothesis $H_0$. To compute the p-value of the visual test, the lineup will be independently presented to a number of participants, asking them to pick the most different plot. Under $H_0$, the data plot is expected to be indistinguishable from the null plots, and the probability of correctly identifying the data plot by an observer is $1/m$. If a large number of participants correctly identify the data plot, the corresponding $p$-value will be small, indicating strong evidence against $H_0$.

This method has gained increasing traction in recent years and has already been integrated into data analysis of various topics [see @loy2013diagnostic; @widen2016graphical; @krishnan2021hierarchical]. However, the reliance of human assessment is a fundamental aspect of visual tests, which may restrict its widespread usage. The lineup protocol is unsuitable for large-scale applications, due to its high labour costs and time requirements. Moreover, it presents significant usability issues for individuals with visual impairments, resulting in reduced accessibility. 

The main objective of this research is to construct an automatic visual inference system capable of conducting visual tests on a large scale in the domain of regression diagnostics, by incorporating modern computer vision models. 

## Comparison of Visual Testing and Conventional Testing in Residual Diagnostics

Despite the availability of numerical hypothesis tests for model diagnosis, regression experts consistently recommend visual inspection of residual plots [@draper1998applied; @cook1982residuals; @montgomery1982introduction]. Chapter 2 provides empirical evidence supporting the indispensability of residual plots through a visual inference experiment using the lineup protocol. By comparing human evaluations of residual plots to conventional statistical tests, this chapter demonstrates the advantages of graphical methods in detecting practical issues with model fit, while also highlighting the limitations of conventional tests in producing overly sensitive results. The chapter contains a comprehensive literature review related to residual diagnostics. 

## Automated Residual Plot Assessment

Chapter 3 introduces a computer vision model to automate the assessment of residual plots, addressing the scalability limitations of human-based visual inference. This model is trained to predict a distance measure based on Kullback-Leibler divergence, quantifying the disparity between the residual distribution of a fitted classical normal linear regression model and the reference distribution. Performance of the model is evaluated on the human subject experiment data collected in chapter 2. A comprehensive literature review of data plots reading with computer vision models is contained in the chapter.

## Implementing Automated Residual Plot Assessment in Practice

Chapter 4 introduces a new R package, `autovi`, and its accompanying web interface, `autovi.web`, designed to automate the assessment of residual plots in regression analysis. The package uses a computer vision model built in Chapter 3 to predict a measure of visual signal strength (VSS) and provides supporting information to assist analysts in diagnosing model fit. By automating this process, `autovi` and `autovi.web` improve the efficiency and consistency of model evaluation, making advanced diagnostic tools accessible to a broader audience. 

## Summary

The thesis is structured as follows. Chapter 2 compares visual testing and conventional testing in residual diagnostics through a visual inference experiment, providing empirical evidence for the effectiveness of visual methods. Chapter 3 introduces a computer vision model for automated residual plot assessment, evaluating its performance on human subject experiment data. Chapter 4 presents the implementation of automated residual plot assessment in practice, through the R package `autovi` and its accompanying web interface `autovi.web`.

Chapter 5 summarises the contribution of the work and their impact, and discusses some future plans.
