# Tools for Automated Residual Plot Assessment: autovi and autovi.web

Regression software is widely available today, but tools for effective diagnostics are still lagging. Although it is advised to diagnose a linear model by plotting residuals, it required human effort which can be prohibit the efforts. Here we describe a new R package that includes a computer vision model for automated assessment of residual plots, and an accompanying shiny app for ease of use. 

## Introduction {#sec-autovi-introduction}

Regression analysis is a fundamental statistical technique widely used for modeling data from many fields. In modern practice, software for regression analysis tools is widely. The Comprehensive R Archive Network (CRAN) [@hornik2012comprehensive] hosts a vast array of packages, many of which diagnosing models using residual plots. These packages can be broadly categorized into three groups: general purpose, enhanced diagnostics, diagnostics with statistical testing.

General-purpose regression analysis tools are the largest and most commonly used group. These packages aren't specifically designed for graphical diagnostics of residuals in linear regression but offer this functionality as part of a broader set of statistical tools. A prime example is R's built-in `stats` package [@stats], which provides a comprehensive collection of statistical modelling tools that includes common diagnostic plots like residuals vs fitted values, quantile-quantile (Q-Q) plots, and residuals vs leverage plots. Other packages such as `jtools` [@jtools], `olsrr` [@olsrr], `rockchalk` [@rockchalk], and `ggResidpanel` [@ggresidpanel] provide similar graphical tools with alternative aesthetic styles or interactive features. Although these packages may differ in presentation, they all fundamentally deliver diagnostic plots based on well-established principles in regression analysis, as outlined in classic works like @cook1982residuals. However, consistently drawing accurate conclusions from these tools can be challenging due to individual differences in interpreting statistical graphics. As noted in @li2024plot, relying solely on subjective assessments of data plots can lead to problems, such as over-interpreting random patterns as model violations.

Enhanced visual diagnostics is the second group, which offers advanced visual aids for interpreting diagnostic plots. A notable example is the `DHARMa` package [@dharma], which uses an innovative approach by fitting quantile regression on scaled residual plots. It compares the empirical 0.25, 0.5, and 0.75 quantiles in scaled residuals with their theoretical counterparts, making it particularly useful for highlighting deviations from model assumptions, detecting model violations such as heteroscedasticity and incorrect functional forms, and uncovering issues specific to generalized linear models and mixed-effect models, like over/underdispersion. By offering these enhanced visualizations, `DHARMa` enables users to more easily identify potential issues in their regression models that might not be immediately apparent with standard diagnostic plots. In summary, this group of packages enhances the interpretability of diagnostic plots by drawing attention to critical elements such as trends, clusters, and outliers. They sometimes automatically perform conventional tests on these elements, displaying the results as annotations, labels, or text within the plot, thereby further reducing the likelihood of misinterpretation.

Statistical testing for visual discoveries is the third group, which focuses on providing tools for conducting formal statistical tests for visual discoveries obtained from diagnostic plots [@buja2009statistical]. Examples in this category include the `nullabor` [@nullabor] and `regressinator` [@regressinator] packages, which enables users to quantify the significance of patterns observed in residual diagnostic plots, perform hypothesis tests on specific aspects of model fit, and validate visual interpretations with statistical evidence. This approach addresses the issue of inconsistent interpretation of diagnostic plots by bridging the gap between visual inspection and formal statistical inference, thus offering a more robust framework for regression diagnostics.

Conducting a visual test for a residual plot, which is among the most common diagnostic plots in regression analysis, involves using a lineup protocol. In this protocol, the true residual plot is embedded within a lineup of several null plots and presented to one or more observers. The null plots are created by simulating residuals consistent with the null hypothesis $H_0$ that the regression model is correctly specified. Observers are then asked to identify the plot that appears most different from the others. If a significant percentage of observers correctly identify the true residual plot, it provides evidence against the $H_0$, as according to @buja2009statistical, the true residual plot would have no distinguishable difference from the null plots if all residuals are generated by the same process.

However, as discussed in @sec-second-paper, the lineup protocol has significant limitations in large-scale applications due to its high labor costs and time consumption. To address these issues, we developed a computer vision model and an associated statistical testing procedure to automate the assessment of residual plots. This model takes a residual plot and a vector of auxiliary variables (such as the number of observations) as inputs and outputs a visual signal strength. This strength estimates the distance between the residual distribution of the fitted regression model and the reference distribution assumed under correct model specification.

By estimating the visual signal strength for all plots in a lineup, we can compute a $p$-value based on the ratio of plots with visual signal strength greater than or equal to that of the true residual plot. This $p$-value has a lower bound of one divided by the number of plots in the lineup. Additionally, we can construct a null distribution of visual signal strength using the strengths of null plots.

We can also apply bootstrapping to obtain a distribution of visual signal strengths. This involves bootstrapping the data used to fit the linear regression model, refitting the model to obtain bootstrapped residuals, and then using the computer vision model to predict visual signal strength for these residuals. The resulting bootstrapped distribution can be compared against the null distribution. If these distributions are largely similar, it suggests that the bootstrapped residual plots are similar to the null plots. The proportion of bootstrapped visual signal strengths exceeding a critical value (such as the 95% sample quantile of the null distribution) indicates how often the assumed regression model would be considered incorrect if the data could be repeatedly obtained from the same data-generating process.

To make the statistical testing procedure and trained computer vision model widely accessible, we developed the R package `autovi`. In addition, we created a web-based tool that offers a user-friendly interface, enabling users to diagnose their residual plots without the need to install any dependencies required by the `autovi` package.

The remainder of this chapter is structured as follows: @sec-autovi provides a detailed documentation of the `autovi` package, including its usage and infrastructure. @sec-autovi-web focuses on the `autovi.web` interface, describing its design and usage, along with illustrative examples. Finally, @sec-autovi-conclusion presents the main conclusions of this work.

## autovi {#sec-autovi}

The main purpose of `autovi` is to provide rejection decisions and $p$-values for testing whether a regression model is correctly specified. The package introduces a novel approach to automating statistical analysis, particularly in the interpretation of residual plots. The name `autovi` stands for automated visual inference. While initially designed for linear regression residual diagnostics, it has the potential to be extended to broader visual inference applications, as we'll discuss in section @sec-autovi-infrastructure.

### Implementation {#sec-autovi-implementation}

`autovi` is built upon the `bandicoot` object-oriented programming (OOP) system [@bandicoot], which marks a departure from R's conventional S3 generic system. The adoption of an OOP architecture enhances flexibility and modularity, enabling users to redefine key functions within the infrastructure through method overriding. While similar functionality could be replicated using R's S3 system with generic functions, the OOP system offers a more structured and extensible foundation for the package.

The infrastructure of `autovi` demonstrates the effective integration of multiple programming languages and libraries to create a comprehensive analytical tool. It depends on five core libraries from Python and R, each contributing critically to the analysis pipeline. In Python, `pillow` [@clark2015pillow] handles image processing tasks, including reading PNG files of residual plots, resizing them, and converting them into input tensors for further analysis. The `TensorFlow` [@abadi2016tensorflow] library, a cornerstone of contemporary machine learning, is employed to predict the visual signal strength of these residual plots,  utilizing a pre-trained convolutional neural network.

Within the R environment, `autovi` utilizes several powerful libraries. `ggplot2` [@ggplot2] is employed to generate the initial residual plots, which are then saved as PNG files, using as the primary visual input for the analysis. The `cassowaryr` [@mason2022cassowaryr] library calculates scagnostics (scatter plot diagnostics) of the residual plots, providing numerical features that capture various statistical properties of the plots. These scagnostics complement the visual analysis by supplying quantitative metrics as secondary input to the computer vision model. The `reticulate` [@reticulate] package is used to bridge R and Python, allowing for seamless communication between the two languages and supporting an integrated infrastructure.

The package includes internal functions to check the current Python environment used by the `reticulate` package. If the necessary Python packages are not installed in the Python interpreter, an error will be raised. If you want to select a specific Python environment, you can do so by calling the `reticulate::use_python()` function before using the `autovi` package.

### Installation

The `autovi` package is available on CRAN. It is actively developed and maintained, with the latest updates accessible on GitHub at [https://github.com/TengMCing/autovi](https://github.com/TengMCing/autovi). The code discussed in this chapter is based on `autovi` version 0.4.1.


### Usage {#sec-autovi-quick-start}

To get started quickly, users need only five lines of code to obtain a summary of the automated residual assessment:






::: {.cell}

:::







```r
library(autovi)
checker <- auto_vi(fitted_model = lm(dist ~ speed, data = cars), 
                   keras_model = get_keras_model("vss_phn_32"))
checker$check()
checker
```






::: {.cell}

:::

::: {.cell}
::: {.cell-output .cell-output-stderr}

```

```


:::

::: {.cell-output .cell-output-stderr}

```
-- <AUTO_VI object>
Status:
 - Fitted model: lm
 - Keras model: (None, 32, 32, 3) + (None, 5) -> (None, 1)
    - Output node index: 1
 - Result:
    - Observed visual signal strength: 3.162 (p-value = 0.0396)
    - Null visual signal strength: [100 draws]
       - Mean: 1.274
       - Quantiles: 
          ╔═════════════════════════════════════════════════╗
          ║   25%    50%    75%    80%    90%    95%    99% ║
          ║0.8021 1.1109 1.5751 1.6656 1.9199 2.6564 3.3491 ║
          ╚═════════════════════════════════════════════════╝
    - Bootstrapped visual signal strength: [100 draws]
       - Mean: 2.786 (p-value = 0.05941)
       - Quantiles: 
          ╔══════════════════════════════════════════╗
          ║  25%   50%   75%   80%   90%   95%   99% ║
          ║2.452 2.925 3.173 3.285 3.463 3.505 3.652 ║
          ╚══════════════════════════════════════════╝
    - Likelihood ratio: 0.7275 (boot) / 0.06298 (null) = 11.55 
```


:::
:::






1. Load the package using the `library()` function.
2. Construct a checker with two inputs: a linear regression model and a pre-trained Keras model [@chollet2015keras].
3. Use `get_keras_model()`, a function provided by `autovi`, to download a trained computer vision model (described in @sec-second-paper) from GitHub. "vss_phn_32" specifies a model that predicts visual signal strength (vss) and is trained on residuals with polynomial, heteroskedasticity, and non-normality patterns (phn). More details about the hosted models will be provided in section @sec-trained-model-hosting.
4. Call the `check()` method of the checker with default arguments. This predicts the visual signal strength for the true residual plot, 100 null plots, and 100 bootstrapped plots, storing the predictions internally.
5. Use the `print()` function to generate a concise report of the check results.

The report highlights key findings such as the visual signal strength of the true residual plot and the $p$-value of the automated visual test. The $p$-value is the ratio of null plots having visual signal strength greater than or equal to the true residual plot. We typically reject the null hypothesis when the $p$-value is smaller than or equal to 5%. The report also provides sample quantiles of visual signal strength for null and bootstrapped plots, helping to explain the severity and likelihood of model violations.

Although the $p$-value is sufficient for automated decision-making, users are strongly encouraged to visually inspect the original residual plot alongside a sample null plot. This visual comparison can clarify why $H_0$ is either rejected or not, and help identify potential remedies. The `plot_pair()` method facilitates this comparison. 






::: {.cell}

```{.r .cell-code}
checker$plot_pair()
```

::: {.cell-output-display}
![](04-chap4_files/figure-pdf/unnamed-chunk-4-1.pdf){fig-pos='H'}
:::
:::






This method displays the true residual plot on the left and a null plot on the right. Users should look for any distinct visual patterns in the true residual plot that are absent in the null plot. It's recommended to run this function multiple times to confirm any visual findings, as each execution generates a new random null plot for comparison.

The package offers a straightforward visualization of the assessment result through the `summary_plot()` function.






::: {.cell}

```{.r .cell-code}
checker$summary_plot()
```

::: {.cell-output-display}
![](04-chap4_files/figure-pdf/unnamed-chunk-5-1.pdf){fig-pos='H'}
:::
:::







In the visualization, the blue area represents the density of visual signal strength for null residual plots, while the red area shows the density for bootstrapped residual plots. The dashed line indicates the visual signal strength of the true residual plot, and the solid line marks the critical value at a 95% significance level. The $p$-value and the likelihood ratio are displayed in the subtitle. The likelihood ratio represents the ratio of the likelihood of observing the visual signal strength of the true residual plot from the bootstrapped distribution compared to the null distribution.

Interpreting the plot involves several key aspects. If the dashed line falls to the right of the solid line, it suggests rejecting the null hypothesis. The degree of overlap between the red and blue areas indicates similarity between the true residual plot and null plots; greater overlap suggests more similarity. Lastly, the portion of the red area to the right of the solid line represents the percentage of bootstrapped models considered to have model violations.

This visual summary provides an intuitive way to assess the model's fit and potential violations, allowing users to quickly grasp the results of the automated analysis.


### Modularized Infrastructure {#sec-autovi-infrastructure}






::: {.cell}
::: {.cell-output-display}
![Diagram illustrating the infrastructure of the R package autovi. The modules in green are primary inputs provided by users. Modules in blue are overridable methods that can be modified to accommodate users' specific needs. The module in yellow is a pre-defined non-overridable method. The modules in red are primary outputs of the package.](04-chap4_files/figure-pdf/fig-autovi-diag-1.png){#fig-autovi-diag width=100%}
:::
:::






The initial motivation for developing `autovi` was to create a convenient interface for sharing the models described and trained in @sec-second-paper. However, recognizing that the classical normal linear regression model represents a restricted class of models, we sought to avoid limiting the potential for future extensions, whether by the original developers or other users. As a result, the package was designed to function seamlessly with linear regression models with minimal modification and few required arguments, while also accommodating other classes of models through partial infrastructure substitution. This modular and customizable design allows `autovi` to handle a wide range of residual diagnostics tasks.

The infrastructure of `autovi` consists of ten core modules: data extraction, bootstrapping and model refitting, fitted values and residuals extraction, auxiliary computation, null residual simulation, plotting, plot saving, image reading and resizing, visual signal strength prediction, and $p$-value computation. Each module is designed with minimal dependency on the preceding modules, allowing users to customize parts of the infrastructure without affecting its overall integrity. An overview of this infrastructure is illustrated in Figure @fig-autovi-diag.

The modules for visual signal strength prediction and $p$-value computation are predefined and cannot be overridden, although users can interact with them directly through function arguments. Similarly, the image reading and resizing module is fixed but will adapt to different Keras models by checking their input shapes. The remaining seven modules are designed to be overridable, enabling users to tailor the infrastructure to their specific needs. These modules will be discussed in detail in the following sections.

#### Initialization

An `autovi` checker can be initialized by supplying two primary inputs, including a regression model object, such as an `lm` object representing the result of a linear regression model, and a trained computer vision model compatible with the `Keras` [@chollet2015keras] Application Programming Interface (API), to the `AUTO_VI` class constructor `auto_vi()`. The input will be stored in the checker and can be accessed by the user through the `$` operator.






::: {.cell}

```{.r .cell-code}
library(autovi)
checker <- auto_vi(fitted_model = lm(dist ~ speed, data = cars), 
                   keras_model = get_keras_model("vss_phn_32"))
```
:::






Optionally, the user may specify the node index of the output layer of the trained computer vision model to be monitored by the checker via the `node_index` argument if there are multiple output nodes. This is particularly useful for multiclass classifiers when the user wants to use one of the nodes as a visual signal strength indicator.

After initializing the object, you can print the checker to view its status.






::: {.cell}

```{.r .cell-code}
checker
```

::: {.cell-output .cell-output-stderr}

```

```


:::

::: {.cell-output .cell-output-stderr}

```
-- <AUTO_VI object>
Status:
 - Fitted model: lm
 - Keras model: (None, 32, 32, 3) + (None, 5) -> (None, 1)
    - Output node index: 1
 - Result: UNKNOWN 
```


:::
:::






The status includes the list of regression model classes (as provided by the built-in `class()` function), the input and output shapes of the Keras model in the standard `Numpy` format [@harris2020array], the output node index being monitored, and the assessment result. If no check has been run yet, the assessment result will display as "UNKNOWN".

#### Fitted Values and Residuals Extraction

To be able to predict visual signal strength for a residual plot, both fitted values and residuals are needed to be extracted from the regression model object supplied by the user. In R, statistical models like `lm` (linear model) and `glm` (generalized linear model) typically support the use of generic functions such as `fitted()` and `resid()` to retrieve these values. The `get_fitted_and_resid()` method, called by the checker, relies on these generic functions by default. However, generic functions only work with classes that have appropriate method implementations. Some regression modelling packages may not fully adhere to the `stats` package guidelines for implementing these functions. In such cases, overriding the method becomes necessary.

By design, the `get_fitted_and_resid()` method accepts a regression model object as input and returns a `tibble` with two columns: `.fitted` and `.resid`, representing the fitted values and residuals, respectively. If no input is supplied, the method uses the regression model object stored in the checker. Although modules in the `autovi` infrastructure make minimal assumptions about other modules, they do require strictly defined input and output formats to ensure data validation and prevent fatal bugs. Therefore, any overridden method should follow to these conventions.






::: {.cell}

```{.r .cell-code}
checker$get_fitted_and_resid()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 50 x 2
   .fitted .resid
     <dbl>  <dbl>
 1   -1.85   3.85
 2   -1.85  11.8 
 3    9.95  -5.95
 4    9.95  12.1 
 5   13.9    2.12
 6   17.8   -7.81
 7   21.7   -3.74
 8   21.7    4.26
 9   21.7   12.3 
10   25.7   -8.68
# i 40 more rows
```


:::
:::







#### Data Extraction

For linear regression model in R, the model frame contains all the data required by a formula for evaluation. This is essential for bootstrapping and refitting the model when constructing a bootstrapped distribution of visual signal strength. Typically, the model frame can be extracted from the regression model object using the `model.frame()` generic function, which is the default method used by `get_data()`. However, some regression models don't use a formula or are evaluated differently, potentially lacking a model frame. In such cases, users can either provide the data used to fit the regression model through the `data` argument when constructing the checker, or customize the method to better suit their needs. It's worth noting that this module is only necessary if bootstrapping is required, as the model frame is not used in other modules of the infrastructure.

The `get_data()` method accepts a regression model object as input and returns a `data.frame` representing the model frame of the fitted regression model. If no input is supplied, the regression model stored in the checker will be used.






::: {.cell}

```{.r .cell-code}
checker$get_data() |> 
  head()
```

::: {.cell-output .cell-output-stdout}

```
  dist speed
1    2     4
2   10     4
3    4     7
4   22     7
5   16     8
6   10     9
```


:::
:::







#### Bootstrapping and Model Refitting

Bootstrapping a regression model typically involves sampling the observations with replacement and refitting the model with the bootstrapped data. The `boot_method()` method follows this bootstrapping scheme by default. It accepts a fitted regression model and a `data.frame` as inputs, and returns a `tibble` of bootstrapped residuals. If no inputs are provided, the method uses the regression model stored in the checker and the result of the `get_data()` method. 

Note that instead of calling `get_data()` implicitly within the method, it is used as part of the default argument definition. This approach allows users to bypass the `get_data()` method entirely and directly supply a `data.frame` to initiate the bootstrap process. Many other methods in `autovi` adopt this principle when possible, where dependencies are explicitly listed in the formal arguments. This design choice enhances the reusability and isolation of modules, offers better control for testing, and simplifies the overall process.






::: {.cell}

```{.r .cell-code}
checker$boot_method(data = checker$get_data())
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 50 x 2
   .fitted .resid
     <dbl>  <dbl>
 1    30.0  -2.04
 2    37.6  -1.58
 3    30.0 -16.0 
 4    52.7 -10.7 
 5    15.0   1.03
 6    30.0 -10.0 
 7    56.4  11.6 
 8    22.5   3.50
 9    37.6  42.4 
10    26.3  -9.27
# i 40 more rows
```


:::
:::






#### Auxiliary Computation

According to @sec-second-paper, in some cases, a residual plot alone may not provide enough information to accurately determine visual signal strength. For instance, when the residual plot has significant overlap, the trend and shape of the residual pattern can be difficult to discern. Including auxiliary variables, such as the number of observations, as additional inputs to the computer vision model can be beneficial. To address this, `autovi` includes internal functions within the checker that automatically detect the number of inputs required by the provided Keras model. If multiple inputs are necessary, the checker invokes the `auxiliary()` method to compute these additional inputs.

The `auxiliary()` method takes a `data.frame` containing fitted values and residuals as input and returns a `data.frame` with five numeric columns. These columns represent four scagnostics — "Monotonic", "Sparse", "Striped", and "Splines" — calculated using the `cassowaryr` package, as well as the number of observations. This approach is consistent with the training process of the computer vision models described in @sec-second-paper. If no `data.frame` is provided, the method will default to retrieving fitted values and residuals by calling `get_fitted_and_resid()`. 

Technically, any Keras-implemented computer vision model can be adapted to accept an image as the primary input and additional variables as secondary inputs by adding a data pre-processing layer before the actual input layer. If users wish to override `auxiliary()`, the output should be a `data.frame` with a single row and the number of columns matching the supplied Keras model.






::: {.cell}

```{.r .cell-code}
checker$auxiliary()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 x 5
  measure_monotonic measure_sparse measure_splines measure_striped     n
              <dbl>          <dbl>           <dbl>           <dbl> <int>
1            0.0621          0.470          0.0901            0.62    50
```


:::
:::







#### Null Residual Simulation {#sec-autovi-null-method}

A fundamental element of the automated residual assessment described in @sec-second-paper is comparing the visual signal strength of null plots with that of the true residual plot. However, due to the variety of regression models, there is no universal method for simulating null residuals that are consistent with model assumptions. Fortunately, for classical normal linear regression models, null residuals can be effectively simulated using the residual rotation method, as outlined in @buja2009statistical. This process involves generating random draws from a standard normal distribution, regressing these draws on the original predictors, and then rescaling the resulting residuals by the ratio of the residual sum of squares to the that of the original linear regression model. Other regression models, such as `glm` (generalized linear model) and `gam` (generalized additive model), generally cannot use this method to efficiently simulate null residuals. Therefore, it is recommended that users override the `null_method()` to suit their specific model. The `null_method()` takes a fitted regression model as input, defaulting to the regression model stored in the checker, and returns a `tibble`.






::: {.cell}

```{.r .cell-code}
checker$null_method()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 50 x 2
   .fitted .resid
     <dbl>  <dbl>
 1   -1.85 -19.0 
 2   -1.85 -17.0 
 3    9.95   3.77
 4    9.95  19.7 
 5   13.9    7.26
 6   17.8  -12.5 
 7   21.7   -2.14
 8   21.7   15.4 
 9   21.7  -19.9 
10   25.7    6.28
# i 40 more rows
```


:::
:::







#### Plotting

Plotting is a crucial aspect of residual plot diagnostics because aesthetic elements like marker size, marker color, and auxiliary lines impact the presentation of information. There are computer vision models trained to handle images captured in various scenarios. For example, the VGG16 model [@simonyan2014very] can classify objects in images taken under different lighting conditions and is robust to image rotation. However, data plots are a special type of image as the plotting style can always be consistent if controlled properly. Therefore, we assume computer vision models built for reading residual plots will be trained with residual plots of a specific aesthetic style. In this case, it is best to predict plots using the same style for optimal performance. The plotting method `plot_resid()` handles this aspect. 

`plot_resid()` accepts a `data.frame` containing fitted values and residuals, along with several customization options: a `ggplot` theme, an `alpha` value to control the transparency of data points, a `size` value to set the size of data points, and a `stroke` value to define the thickness of data point edges. Additionally, it includes four Boolean arguments to toggle the display of axes, legends, grid lines, and a horizontal red line. By default, it replicates the style we used to generate the training samples for the computer vision models described in @sec-second-paper. In brief, the residual plot omits axis text and ticks, titles, and background grid lines, featuring only a red line at $y = 0$. It retains only the necessary components of a residual plot. If the computer vision model is trained with a different but consistent aesthetic style, `plot_resid()` should be overridden. 

The method returns a `ggplot` object, which can be saved as a PNG file in the following module. If no data is provided, the method will use `get_fitted_and_resid()` to retrieve the fitted values and residuals from the regression model stored in the checker.






::: {.cell}

```{.r .cell-code}
checker$plot_resid()
```

::: {.cell-output-display}
![](04-chap4_files/figure-pdf/unnamed-chunk-14-1.pdf){fig-pos='H'}
:::
:::







To manually generate true residual plots, null plots, or bootstrapped residual plots, you can pass the corresponding `data.frame` produced by the `get_fitted_and_resid()`, `null_method()`, and `boot_method()` methods to the `plot_resid()` method, respectively.






::: {.cell}

```{.r .cell-code}
checker$null_method() |>
  checker$plot_resid()
```

::: {.cell-output-display}
![](04-chap4_files/figure-pdf/unnamed-chunk-15-1.pdf){fig-pos='H'}
:::
:::







#### Plot Saving

Another key aspect of a standardized residual plot is its resolution. In @sec-second-paper, we used an image format of 420 pixels in height and 525 pixels in width. This resolution was chosen because the original set, consisting of 20 residual plots arranged in a four by five grid, was represented by an image of 2100 by 2100 pixels. The `save_plot()` method takes a `ggplot` object as input, saves it as a temporary PNG file, and returns the file path as a string. Note that the `save_plot()` method does not have default arguments, as it is not intended to be called without a plot. While an alternative design could be to save the true residual plot by default, this might be confusing for users, given that the method's name does not fully convey this functionality.






::: {.cell}

```{.r .cell-code}
checker$plot_resid() |> 
  checker$save_plot()
```

::: {.cell-output .cell-output-stdout}

```
[1] "/var/folders/61/bv7_1qzs20x6fjb2rsv7513r0000gn/T//Rtmp5LCDUO/file1118621dd3880.png"
```


:::
:::






#### Image Reading and Resizing

When training computer vision models, it is common to test various input sizes for the same architecture to identify the optimal setup. This involves preparing the original training image at a higher resolution than required and then resizing it to match the input size during training. The `autovi` package includes a class, `KERAS_WRAPPER`, to simplify this process. This Keras wrapper class features a method called `image_to_array()`, which reads an image as a `PIL` image using the `pillow` Python package, resizes it to the target input size required by the Keras model, and converts it to a `Numpy` array.

To construct a `KERAS_WRAPPER` object, you need to provide the Keras model as the main argument. However, users generally do not need to interact with this class directly, as the `autovi` checker automatically invokes its methods when performing visual signal strength predictions. The `image_to_array()` method takes the path to the image file, the target height, and the target width as inputs and returns a `Numpy` array. If not specified, the target height and target width will be retrieved from the input layer of the Keras model by the `get_input_height()` and `get_input_width()` method of `KERAS_WRAPPER`. 

The following code example demonstrate the way to manually generate the true residual plot, save it as PNG file, and load it back as `Numpy` array.






::: {.cell}

```{.r .cell-code}
wrapper <- keras_wrapper(keras_model = checker$keras_model)  
input_array <- checker$plot_resid() |> 
  checker$save_plot() |>
  wrapper$image_to_array()
input_array$shape
```

::: {.cell-output .cell-output-stdout}

```
(1, 32, 32, 3)
```


:::
:::







#### Visual Signal Strength Prediction

Visual signal strength, as discussed in @sec-second-paper, estimates the distance between the input residual plot and a theoretically good  residual plot. It can be defined in various ways, much like different methods for measuring the distance between two points. This will not impact the `autovi` infrastructure as long as the provided Keras model can predict the intended measure.

There are several ways to obtain visual signal strength from the checker, with the most direct being the `vss()` method. By default, this method predicts the visual signal strength for the true residual plot. If a `ggplot` or a `data.frame`, such as null residuals generated by the `null_method()`, is explicitly provided, the method will use that input to predict visual signal strength accordingly. Note that if a `ggplot` is provided, auxiliary inputs must be supplied manually via the `auxiliary` argument, as we assume that auxiliary variables can not be computed directly from a `ggplot`.

Another way to obtain visual signal strength is by calling the `check()` method. This comprehensive method perform extensive diagnostics on the true residual plot and store the visual signal strength in the `check_result` field of the checker. Additionally, for obtaining visual signal strength for null residual plots and bootstrapped residual plots, there are two specialized methods, `null_vss()` and `boot_vss()`, designed for this purpose respectively.

Calling the `vss()` method without arguments will predict the visual signal strength for the true residual plot and return the result as a single-element `tibble`.






::: {.cell}

```{.r .cell-code}
checker$vss()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 x 1
    vss
  <dbl>
1  3.16
```


:::
:::






Providing a `data.frame` of null residuals or a null residual plot yields the same visual signal strength.






::: {.cell}

```{.r .cell-code}
null_resid <- checker$null_method()
checker$vss(null_resid)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 x 1
    vss
  <dbl>
1  1.02
```


:::
:::

::: {.cell}

```{.r .cell-code}
null_resid |>
  checker$plot_resid() |>
  checker$vss()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 x 1
    vss
  <dbl>
1  1.02
```


:::
:::






The `null_vss()` helper method primarily takes the number of null plots as input. If the user wants to use a ad hoc null simulation scheme, it can be provided via the `null_method` argument. Intermediate results, including null residuals and null plots, can be returned by enabling `keep_null_data` and `keep_null_plot`. The visual signal strength, along with null residuals and null plots, will be stored in a `tibble` with three columns. The following code example demonstrates how to predict the visual signal strength for five null residual plots while keeping the intermediate results.






::: {.cell}

```{.r .cell-code}
checker$null_vss(5L, 
                 keep_null_data = TRUE, 
                 keep_null_plot = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 5 x 3
    vss data              plot  
  <dbl> <list>            <list>
1 1.35  <tibble [50 x 2]> <gg>  
2 0.629 <tibble [50 x 2]> <gg>  
3 1.77  <tibble [50 x 2]> <gg>  
4 1.91  <tibble [50 x 2]> <gg>  
5 1.71  <tibble [50 x 2]> <gg>  
```


:::
:::






The `boot_vss()` helper method is similar to `null_vss()`, with some differences in argument names. The following code example demonstrates how to predict the visual signal strength for five bootstrapped residual plots while keeping the intermediate results.






::: {.cell}
::: {.cell-output .cell-output-stdout}

```
# A tibble: 5 x 3
    vss data              plot  
  <dbl> <list>            <list>
1  1.26 <tibble [50 x 2]> <gg>  
2  3.35 <tibble [50 x 2]> <gg>  
3  3.16 <tibble [50 x 2]> <gg>  
4  2.87 <tibble [50 x 2]> <gg>  
5  2.54 <tibble [50 x 2]> <gg>  
```


:::
:::






#### $P$-value Computation

Once we have obtained the visual signal strength from both the true residual plot and the null plots, we can compute the $p$-value. This $p$-value represents the ratio of plots with visual signal strength greater than or equal to that of the true residual plot. We can perform this calculation using the `check()` method. The main inputs for this method are the number of null plots and the number of bootstrapped plots to generate. If you need to access intermediate residuals and plots, you can enable the `keep_data` and `keep_plot` options. The method stores the final result in the `check_result` field of the object. To obtain the p-value using the `check()` method, you can use the following code.






::: {.cell}

```{.r .cell-code}
checker$check(boot_draws = 100L, null_draws = 100L)
checker$check_result$p_value
```

::: {.cell-output .cell-output-stdout}

```
[1] 0.01980198
```


:::
:::






You can also check the $p$-value by printing the checker, which includes it in the summary report.






::: {.cell}

```{.r .cell-code}
checker
```

::: {.cell-output .cell-output-stderr}

```

```


:::

::: {.cell-output .cell-output-stderr}

```
-- <AUTO_VI object>
Status:
 - Fitted model: lm
 - Keras model: (None, 32, 32, 3) + (None, 5) -> (None, 1)
    - Output node index: 1
 - Result:
    - Observed visual signal strength: 3.162 (p-value = 0.0198)
    - Null visual signal strength: [100 draws]
       - Mean: 1.42
       - Quantiles: 
          ╔═════════════════════════════════════════════════╗
          ║   25%    50%    75%    80%    90%    95%    99% ║
          ║0.9296 1.3095 1.7277 1.7810 2.2497 2.5835 3.1570 ║
          ╚═════════════════════════════════════════════════╝
    - Bootstrapped visual signal strength: [100 draws]
       - Mean: 2.623 (p-value = 0.05941)
       - Quantiles: 
          ╔══════════════════════════════════════════╗
          ║  25%   50%   75%   80%   90%   95%   99% ║
          ║2.144 2.770 3.160 3.256 3.444 3.589 3.705 ║
          ╚══════════════════════════════════════════╝
    - Likelihood ratio: 0.5334 (boot) / 0.02943 (null) = 18.12 
```


:::
:::






### Summary Plots

After executing the `check()` method, `autovi` offers two visualization options for the assessment result through the `summary_plot()` method, including the density plot and the rank plot. We have already discussed and interpreted the density plot in an earlier section. Here, we would like to highlight the flexibility in choosing which elements to display in the density plot. For instance, you can omit the bootstrapped distribution by setting `boot_dist` to `NULL`. Similarly, you can hide the null distribution (`null_dist`), the $p$-value (`p_value`), or the likelihood ratio (`likelihood_ratio`) as needed. The following example demonstrates how to create a summary plot without the results from bootstrapped plots.






::: {.cell}

```{.r .cell-code}
checker$summary_plot(boot_dist = NULL,
                     likelihood_ratio = NULL)
```

::: {.cell-output-display}
![](04-chap4_files/figure-pdf/unnamed-chunk-25-1.pdf){fig-pos='H'}
:::
:::






This customization allows you to focus on specific aspects of the assessment, tailoring the visualization to your analytical needs.

The rank plot, creating by setting `type` to "rank", is a bar plot where the x-axis represents the rank and the y-axis shows the visual signal strength. The bar for the true residual plot is colored in red. By examining the rank plot, you can intuitively understand how the observed visual signal strength compares to the null visual signal strengths and identify any outliers in the null distribution.






::: {.cell}

```{.r .cell-code}
checker$summary_plot(type = "rank")
```

::: {.cell-output-display}
![](04-chap4_files/figure-pdf/unnamed-chunk-26-1.pdf){fig-pos='H'}
:::
:::







### Feature Extraction

In addition to predicting visual signal strength and computing $p$-values, `autovi` offers methods to extract features from any layer of the Keras model. To see which layers are available in the current Keras model, you can use the `list_layer_name()` method from the `KERAS_WRAPPER` class.

The following code example lists the layer names of the currently used Keras model:






::: {.cell}

```{.r .cell-code}
wrapper <- keras_wrapper(checker$keras_model)
wrapper$list_layer_name()
```

::: {.cell-output .cell-output-stdout}

```
 [1] "input_1"                  "tf.__operators__.getitem"
 [3] "tf.nn.bias_add"           "grey_scale"              
 [5] "block1_conv1"             "batch_normalization"     
 [7] "activation"               "block1_conv2"            
 [9] "batch_normalization_1"    "activation_1"            
[11] "block1_pool"              "dropout"                 
[13] "block2_conv1"             "batch_normalization_2"   
[15] "activation_2"             "block2_conv2"            
[17] "batch_normalization_3"    "activation_3"            
[19] "block2_pool"              "dropout_1"               
[21] "block3_conv1"             "batch_normalization_4"   
[23] "activation_4"             "block3_conv2"            
[25] "batch_normalization_5"    "activation_5"            
[27] "block3_conv3"             "batch_normalization_6"   
[29] "activation_6"             "block3_pool"             
[31] "dropout_2"                "block4_conv1"            
[33] "batch_normalization_7"    "activation_7"            
[35] "block4_conv2"             "batch_normalization_8"   
[37] "activation_8"             "block4_conv3"            
[39] "batch_normalization_9"    "activation_9"            
[41] "block4_pool"              "dropout_3"               
[43] "block5_conv1"             "batch_normalization_10"  
[45] "activation_10"            "block5_conv2"            
[47] "batch_normalization_11"   "activation_11"           
[49] "block5_conv3"             "batch_normalization_12"  
[51] "activation_12"            "block5_pool"             
[53] "dropout_4"                "global_max_pooling2d"    
[55] "additional_input"         "concatenate"             
[57] "dense"                    "dropout_5"               
[59] "activation_13"            "dense_1"                 
```


:::
:::






Among these layers, the "global_max_pooling2d" layer is a 2D global max pooling layer that outputs the results from the last convolutional blocks. As @simonyan2014very noted, all preceding convolutional blocks can be viewed as a large feature extractor. Consequently, the output from this layer provides features that can be utilized for various purposes, such as performing transfer learning.

To obtain the features, provide the layer name using the `extract_feature_from_layer` argument in the `predict()` method. This will return a `tibble` with the visual signal strength and all features extracted from that layer. Each row corresponds to one plot. The features will be flattened into 2D and named with the prefix "f_" followed by a number from one to the total number of features.






::: {.cell}

```{.r .cell-code}
checker$plot_resid() |>
  checker$save_plot() |>
  wrapper$image_to_array() |>
  wrapper$predict(auxiliary = checker$auxiliary(),
                  extract_feature_from_layer = "global_max_pooling2d")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 x 257
    vss   f_1   f_2   f_3   f_4   f_5    f_6   f_7    f_8   f_9   f_10  f_11
  <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>  <dbl> <dbl>  <dbl> <dbl>  <dbl> <dbl>
1  3.16 0.151     0     0     0     0 0.0203 0.109 0.0203     0 0.0834     0
# i 245 more variables: f_12 <dbl>, f_13 <dbl>, f_14 <dbl>, f_15 <dbl>,
#   f_16 <dbl>, f_17 <dbl>, f_18 <dbl>, f_19 <dbl>, f_20 <dbl>, f_21 <dbl>,
#   f_22 <dbl>, f_23 <dbl>, f_24 <dbl>, f_25 <dbl>, f_26 <dbl>, f_27 <dbl>,
#   f_28 <dbl>, f_29 <dbl>, f_30 <dbl>, f_31 <dbl>, f_32 <dbl>, f_33 <dbl>,
#   f_34 <dbl>, f_35 <dbl>, f_36 <dbl>, f_37 <dbl>, f_38 <dbl>, f_39 <dbl>,
#   f_40 <dbl>, f_41 <dbl>, f_42 <dbl>, f_43 <dbl>, f_44 <dbl>, f_45 <dbl>,
#   f_46 <dbl>, f_47 <dbl>, f_48 <dbl>, f_49 <dbl>, f_50 <dbl>, f_51 <dbl>, ...
```


:::
:::






Alternatively, the `AUTO_VI` class provides a way to extract features using the `vss()` method. This method is essentially a high-level wrapper around the `predict()` method of `KERAS_WRAPPER`, but it offers a more straightforward interface and better default arguments.

The results from the previous code example can be replicated with a single line of code as shown below.






::: {.cell}

```{.r .cell-code}
checker$vss(extract_feature_from_layer = "global_max_pooling2d")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 x 257
    vss   f_1   f_2   f_3   f_4   f_5    f_6   f_7    f_8   f_9   f_10  f_11
  <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>  <dbl> <dbl>  <dbl> <dbl>  <dbl> <dbl>
1  3.16 0.151     0     0     0     0 0.0203 0.109 0.0203     0 0.0834     0
# i 245 more variables: f_12 <dbl>, f_13 <dbl>, f_14 <dbl>, f_15 <dbl>,
#   f_16 <dbl>, f_17 <dbl>, f_18 <dbl>, f_19 <dbl>, f_20 <dbl>, f_21 <dbl>,
#   f_22 <dbl>, f_23 <dbl>, f_24 <dbl>, f_25 <dbl>, f_26 <dbl>, f_27 <dbl>,
#   f_28 <dbl>, f_29 <dbl>, f_30 <dbl>, f_31 <dbl>, f_32 <dbl>, f_33 <dbl>,
#   f_34 <dbl>, f_35 <dbl>, f_36 <dbl>, f_37 <dbl>, f_38 <dbl>, f_39 <dbl>,
#   f_40 <dbl>, f_41 <dbl>, f_42 <dbl>, f_43 <dbl>, f_44 <dbl>, f_45 <dbl>,
#   f_46 <dbl>, f_47 <dbl>, f_48 <dbl>, f_49 <dbl>, f_50 <dbl>, f_51 <dbl>, ...
```


:::
:::






The argument `extract_feature_from_layer` is also available in other functions that build on the `vss()` method, including `null_vss()`, `boot_vss()`, and `check()`.

The package provides tools for analyzing these extracted features through the `feature_pca()` method and its associated visualization method, `feature_pca_plot()`. The `feature_pca()` method performs principal component analysis (PCA) on the features to reduce their dimensionality. However, it requires that a `check()` is performed first, as it relies on results stored in `check_result`. Alternatively, you can manually provide features using the `feature`, `null_feature`, and `boot_feature` arguments for the true residual plot, null plots, and bootstrapped plots, respectively. The `feature_pca()` method returns a tibble containing both the original features and the principal components. The rotation matrix and standard deviations of each principal component are stored as attributes.






::: {.cell}

```{.r .cell-code}
checker$check(null_draws = 100L,
              boot_draws = 100L,
              extract_feature_from_layer = "global_max_pooling2d")
checker$feature_pca()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 201 x 458
     f_1   f_2   f_3   f_4   f_5    f_6     f_7    f_8   f_9   f_10   f_11
   <dbl> <dbl> <dbl> <dbl> <dbl>  <dbl>   <dbl>  <dbl> <dbl>  <dbl>  <dbl>
 1 0.151 0     0     0     0     0.0203 0.109   0.0203 0     0.0834 0     
 2 1.17  1.87  2.10  1.99  0.646 0.806  1.16    1.12   1.11  0.230  1.77  
 3 0.898 1.95  1.89  1.98  0.683 0.783  1.09    1.03   1.08  0.401  1.62  
 4 0.699 2.64  2.41  3.27  1.41  1.29   1.94    1.50   1.26  1.16   2.50  
 5 0.494 1.22  0.836 0.867 0     0.212  0.231   0.172  0.835 0      0.589 
 6 0.356 0.912 0.203 0.589 0     0      0.0225  0.142  0.485 0.0311 0.162 
 7 0.514 1.25  0.817 0.900 0     0.165  0.176   0.172  0.833 0      0.589 
 8 1.13  2.15  2.30  2.26  0.785 0.932  1.31    1.21   1.25  0.363  1.95  
 9 0.270 0.795 0.123 0.438 0     0      0       0.0272 0.501 0      0.0608
10 0.245 0.807 0     0.357 0     0      0.00358 0.0494 0.426 0      0     
# i 191 more rows
# i 447 more variables: f_12 <dbl>, f_13 <dbl>, f_14 <dbl>, f_15 <dbl>,
#   f_16 <dbl>, f_17 <dbl>, f_18 <dbl>, f_19 <dbl>, f_20 <dbl>, f_21 <dbl>,
#   f_22 <dbl>, f_23 <dbl>, f_24 <dbl>, f_25 <dbl>, f_26 <dbl>, f_27 <dbl>,
#   f_28 <dbl>, f_29 <dbl>, f_30 <dbl>, f_31 <dbl>, f_32 <dbl>, f_33 <dbl>,
#   f_34 <dbl>, f_35 <dbl>, f_36 <dbl>, f_37 <dbl>, f_38 <dbl>, f_39 <dbl>,
#   f_40 <dbl>, f_41 <dbl>, f_42 <dbl>, f_43 <dbl>, f_44 <dbl>, f_45 <dbl>, ...
```


:::
:::







The `feature_pca_plot()` method visualizes the results of the PCA. By default, it plots the first principal component on the x-axis and the second principal component on the y-axis, with points colored according to their origi, true residual plots, null residual plots, or bootstrapped residual plots. Users can customize the x and y axes by specifying symbols for the `x` and `y` arguments. Additionally, the `col_by_set` option can be disabled if you prefer not to use coloring.






::: {.cell}

```{.r .cell-code}
checker$feature_pca_plot()
```

::: {.cell-output-display}
![](04-chap4_files/figure-pdf/unnamed-chunk-31-1.pdf){fig-pos='H'}
:::
:::






When interpreting the principal component scatter plot, look for any outliers within the null or bootstrapped groups. Assess whether the null group and the bootstrapped group form a single cluster or distinct clusters. Additionally, evaluate whether the observed point is distinct from the null group.

### Trained Model Hosting {#sec-trained-model-hosting}

The trained computer vision models described in @sec-second-paper are hosted on a GitHub repository at [https://github.com/TengMCing/autovi_data](https://github.com/TengMCing/autovi_data). Currently, there are six models available. You can view them by calling `list_keras_model()`, which will return a `tibble` showing the input shape and a description of each model.






::: {.cell}
::: {.cell-output .cell-output-stdout}

```
# A tibble: 6 x 7
  model_name  path  input_height input_width input_channels auxiliary_input_size
  <chr>       <chr>        <int>       <int>          <int>                <int>
1 vss_32      kera~           32          32              3                    0
2 vss_64      kera~           64          64              3                    0
3 vss_128     kera~          128         128              3                    0
4 vss_phn_32  kera~           32          32              3                    5
5 vss_phn_64  kera~           64          64              3                    5
6 vss_phn_128 kera~          128         128              3                    5
# i 1 more variable: description <chr>
```


:::
:::






The `get_keras_model()` function can be used to download a model to a temporary directory and load it into memory using `TensorFlow`. It requires only the model name, which is the value in the first column of the `tibble` returned by `list_keras_model()`.

### Extending the `AUTO_VI` class

`bandicoot` is a lightweight object-oriented system with Python-like syntax that supports multiple inheritance and incorporates a Python-like method resolution order. The system is inspired by the OOP frameworks implemented in R6 [r6] and Python. In this section, we will provide essential details for extending the `autovi::AUTO_VI` class using `bandicoot`.

In `bandicoot`, a class is declared using the `bandicoot::new_class()` function, where parent classes are provided as positional arguments, and the class name is specified through the `class_name` argument. The output of `bandicoot::new_class()` is an environment with the S3 class `bandicoot_oop`. Printing a `bandicoot` object provides a summary of the object, which can be customized via the `..str..` magic method.






::: {.cell}

:::






An extended class inherits attributes and methods from its parent class(es), so it will behave similarly to them. This can be verified using the built-in `names()` function.






::: {.cell}
::: {.cell-output .cell-output-stdout}

```
 [1] "vss"                  "rotate_resid"         "..init.."            
 [4] "plot_lineup"          "get_data"             "has_attr"            
 [7] "lineup_check"         "null_vss"             "check_result"        
[10] "summary_plot"         "..str.."              "..new.."             
[13] "del_attr"             "plot_resid"           "null_method"         
[16] "..class.."            "..method_env.."       "auxiliary"           
[19] "summary"              "set_attr"             "get_attr"            
[22] "summary_density_plot" "get_fitted_and_resid" "..methods.."         
[25] "..class_tree.."       "..repr.."             "feature_pca"         
[28] "plot_pair"            "check"                "boot_vss"            
[31] "feature_pca_plot"     "boot_method"          "save_plot"           
[34] "summary_rank_plot"    "instantiate"          "p_value"             
[37] "..instantiated.."     "..type.."             "..dir.."             
[40] "..len.."              "..bases.."            "..mro.."             
[43] "likelihood_ratio"    
```


:::
:::







To register a method for an extended class, you need to pass the class as the first argument and the method as a named argument to the `bandicoot::register_method()` function. Within a method, `self` can be used as a reference to the class or object environment. The following code example overrides the `null_method()` with a function that simulates null residuals from the corresponding normal distribution. This approach differs from the default null residual simulation scheme described in @sec-autovi-null-method. Although less efficient than the default method for linear regression models, it provides an alternative way to simulate null residuals. This method is particularly useful when the fitted model is unavailable, and only the fitted values and residuals are accessible, as discussed in @sec-autovi-web.






::: {.cell}
::: {.cell-output .cell-output-stdout}

```
# A tibble: 50 x 2
   .fitted .resid
     <dbl>  <dbl>
 1   -1.85 -16.8 
 2   -1.85   7.40
 3    9.95 -25.5 
 4    9.95  15.9 
 5   13.9    1.82
 6   17.8   -6.60
 7   21.7   -8.77
 8   21.7   19.6 
 9   21.7  -10.8 
10   25.7   16.2 
# i 40 more rows
```


:::
:::






To create an object in `bandicoot`, you need to call the `instantiate()` method of a class. Alternatively, you can build a convenient class constructor for your class. It is recommended to provide the full list of arguments in the class constructor instead of using `...`, as this makes it easier for integrated development environments (IDEs) like RStudio to offer argument completion hints to the user.






::: {.cell}

:::







## autovi.web {#sec-autovi-web}

In @sec-autovi-implementation, we discussed how `autovi` relies on several Python libraries, with a particularly strong dependency on `TensorFlow`. Managing a Python environment and correctly installing `TensorFlow` on a local machine can be challenging for many users. Moreover, `TensorFlow` is a massive library that undergoes continuous development, which inevitably leads to compatibility issues arising from differences in library versions. These challenges can create significant barriers for users who want to perform residual assessments with the `autovi` package.

Recognizing these potential barriers, we were motivated to design and implement a web interface called `autovi.web`. This web-based solution offers several major advantages. First, it eliminates dependency issues, so users no longer need to struggle with complex Python environments or worry about installing and maintaining the correct versions of libraries. The web interface handles all these dependencies on the server side. Second, `autovi.web` lowers the entry barrier by being user-friendly and accessible to individuals who may not be familiar with R programming. This broadens the potential user base of `autovi`, allowing more researchers and analysts to benefit from its capabilities. Third, by running on a controlled server environment, `autovi.web` ensures a consistent experience for all users, regardless of their local machine setup. Additionally, the web interface can be updated centrally, ensuring that all users always have access to the latest features and improvements without needing to manage updates locally. Lastly, `autovi.web` offers cross-platform accessibility, allowing users to access it from any device with a web browser, increasing flexibility and convenience.

By providing this web interface, we aim to significantly reduce the technical hurdles associated with using `autovi`, making advanced residual assessment techniques more accessible to a wider audience of researchers and data analysts. This approach aligns with modern trends in data science tools, where web-based interfaces are increasingly used to make advanced analytical techniques more widely available.

### Implementation

`autovi.web` is a sophisticated web application built using the `shiny` and `shinydashboard` R packages. Hosted on the [shinyapps.io](https://www.shinyapps.io) domain, the application is accessible through any modern web browser, offering advantages such as scalability and ease of maintenance.

In our initial planning for `autovi.web`, we considered implementing the entire web application using the `webr` framework, which would have allowed the entire application to run directly in the user's browser. However, this approach was not feasible at the time of writing this chapter. The reason is that one of the R packages `autovi` depends on, `splanes`, uses compiled Fortran code. Unfortunately, a working Emscripten version of this code, which would be required for `webr`, was not available.

We also explored the possibility of implementing the web interface using frameworks built on other languages, such as Python. However, server hosting domains that natively support Python servers typically do not have the latest version of R installed. Calling R from Python is typically done using the `rpy2` Python library, but this approach can be awkward when dealing with language syntax related to non-standard evaluation, making it challenging to develop our application in this manner. Another option we considered was renting a server where we could have full control, such as those provided by cloud platforms like Google Cloud Platform (GCP) or Amazon Web Services (AWS). However, correctly setting up the server and ensuring a secure deployment requires significant expertise, which we did not possess at the time. Ultimately, we decided that the most pragmatic solution was to use the `shiny` and `shinydashboard` frameworks, which are well-established in the R community and offer a robust foundation for web application development. This approach allowed us to build `autovi.web` on top of a familiar and well-supported ecosystem, while still taking advantage of the flexibility and power of the underlying Python libraries used by `autovi`.

The server-side configuration of `autovi.web` is carefully designed to support its functionality. Most required Python libraries, including `pillow` and `NumPy`, are pre-installed on the server. These libraries are seamlessly integrated into the Shiny application using the `reticulate` package, which provides a robust interface between R and Python.

Due to the nature of shinyapps.io's resource allocation, the server enters a sleep mode during periods of inactivity, resulting in the clearing of the local Python virtual environment. Consequently, when the application "wakes up" for a new user session, these libraries need to be reinstalled. While this ensures a clean environment for each session, it may lead to slightly longer loading times for the first user after a period of inactivity.

In contrast to `autovi`, `autovi.web` does not use the native Python version of `TensorFlow`. Instead, it leverages `TensorFlow.js`, a JavaScript library that allows the execution of machine learning models directly in the browser. This choice enables native browser execution, enhancing compatibility across different user environments, and shifts the computational load from the server to the client-side, allowing for better scalability and performance, especially when dealing with resource-intensive computer vision models on shinyapps.io. While `autovi` requires downloading pre-trained computer vision models from GitHub, these models in ".keras" file format are incompatible with `TensorFlow.js`. Therefore, we store the model weights in JSON files and include them as extra resources in the Shiny application. When the application initializes, `TensorFlow.js` rebuilds the computer vision model using these pre-stored weights.

To allow communication between `TensorFlow.js` and other components of the Shiny application, the `shinyjs` R package is used. This package allows for the seamless integration of custom JavaScript code into the Shiny framework. The specialized JavaScript code for initializing `TensorFlow.js` and calling `TensorFlow.js` for visual signal strength prediction is deployed alongside the Shiny application as additional resources.




<!-- Furthermore, the computer vision model used in `autovi` requires a fixed-size 4D tensor as input. The dimensions of this tensor are as follows: the first dimension represents the batch size, the second dimension represents the width of the image, the third dimension represents the height of the image, and the fourth dimension represents the number of channels. The model outputs a numeric vector that represents the visual signal strength for each image in the batch. The computer vision model is also trained with a set of fixed-aesthetic residual plots, which means that the input images must be produced using the same data pipeline that was used for the training data preparation. This consistency is crucial for ensuring that the model can accurately interpret and analyze new data. -->

<!-- A significant portion of our web interface is dedicated to managing this data pipeline. This involves processing the user-provided data to generate input images that conform to the required format for the computer vision model. The pipeline ensures that the residual plots created from the user data match the aesthetics and format of the training data, enabling the model to provide accurate visual signal strength assessments. -->

<!-- Our web interface simplifies this process for the user by automating the necessary steps to transform their data into the appropriate input format. Users can upload their CSV files, and the interface handles the extraction of residuals, the creation of residual plots, and the formatting of these plots into 4D tensors. This seamless integration allows users to focus on interpreting the results rather than on the technical details of data preparation. -->

### Data Pipeline

In this section, we will describe the entire data pipeline, including handling uploaded data, creating and saving fixed-aesthetic residual plots, loading and transforming images to the desired input format, and predicting visual signal strength.

#### Input File Format

As described in Section \ref{background}, the `autovi` package requires a regression model object to initialize the diagnostics. However, it is impractical to ask users to upload an R regression model object for inspection. There are several reasons for this: 

1. **User Complexity**: Saving an R object to the filesystem involves extra steps and requires users to have specific knowledge.
2. **Data Sensitivity**: The regression model object may contain sensitive, non-shareable data.
3. **File Size**: The R object is often unnecessarily large because it contains extra information not needed for diagnostics.

To simplify the process, the web interface instead requests a CSV file. This CSV file should contain at least two columns: `.fitted`, representing the fitted values, and `.resid`, representing the residuals. Additionally, it can contain an optional column `.sample` to indicate the ID of the residual plot. This is particularly useful if the user wants to evaluate a lineup of residual plots.

Compared to an R model object, a CSV file can be easily generated by various software programs, not just R. CSV files are widely accepted and can be easily viewed and modified using common desktop applications like Excel. CSV files are generally less sensitive than raw data because most information about the predictors is excluded. 

#### Plot Drawing and Image Loading

The training data for the computer vision models consist of $32 \times 32$ RGB residual plots. These plots display fitted values on the x-axis and residuals on the y-axis. All labels, including axis texts, are excluded, and no background grid lines are included in the plots. Residual points are drawn in black with a size of 0.5 points, where there are 72.27 points per inch. Additionally, a horizontal red line is drawn at $y = 0$ to help the computer vision model determine if the residual points are uniformly distributed on both sides of the line. The plot is then saved as a PNG file with a resolution of $420 \times 525$ pixels. This resolution mimics a typical lineup residual plot, which has a resolution of $2100 \times 2100$ pixels and is arranged in four rows and five columns.

The uploaded CSV file will be partitioned based on the values in the optional column `k`. If no optional column `k` is present, the entire data set will be used as one partition. Each partition will utilize the plot specifications to generate one residual plot and produce one PNG file.

The saved PNG plot is loaded as an array, where each entry contains a pixel value of the image. This array is then resized to match the input layer shape of the computer vision model, which is $1 \times 32 \times 32 \times 3$. If multiple images are needed for visual signal strength estimation, the arrays can be stacked together to form a larger array with the shape $n \times 32 \times 32 \times 3$, where $n$ is the number of images.

#### Visual Signal Strength Estimation

Finally, the processed image array will be fed into the computer vision model, and returned a vector of visual signal strength which are numerical values always greater than zero.
 
### Software Stack

#### Backend

To utilize the `autovi` R package, the server hosting our web interface must have a functional R interpreter. A static HTML page cannot accomplish this task, as it only serves static resources to the client and lacks the capability to execute R code. The alternative option would be WebR, a version of R designed to run within a web browser. However, integrating WebR introduces complexities into the design of the web interface, which we will explore further in Section XXX. Additionally, 
The resizing of the image is originally done by the Python `Pillow` library. To maintain the same data pipeline, we also need a working Python interpreter. Given the required conditions, we have three options: (1) Use a traditional backend like the `Spring` framework written in Java for handling all the income and outcome traffic of the web interface. Meanwhile, install R and Python in the server and call them when needed. (2) Use a Python backend framework like `Flask` so that the `Pillow` library can be used natively. Still, R needs to be installed and correctly configured in the server and called when needed. (3) Use a R backend framework like `Shiny`. This is similar to the second option, but requires to install and configure Python separately.

Option one requires a good understanding




<!-- Thus, we chose to implement the web interface with a shiny server. Shiny server is a backend framework written in R, so it allows us to receive user's input and interactively update the output rendered on the client side using R code.  -->

<!-- We deploy the shiny server using the services provided by Posit, called `shinyapps.io`. It is responsible for reading in the uploaded CSV file with the `readr` R package, splitting the dataset with the `dplyr` R package and drawing the residual plots with the `ggplot2` R package. The resulting PNG files are stored in the temporary directory of the remote machine. -->


<!-- The saved PNG file  -->


#### Frontend



#### Communications between Software

### Distribute Keras Model Files

### Performance Optimization

## Conclusions
