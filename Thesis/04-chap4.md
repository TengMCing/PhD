# autovi.web: A Web-Based Tool for Residual Plot Diagnostics

## Introduction {#sec-web-introduction}

Most statistical software provides graphical approaches for diagnosing regression models. Typically, this involves generating statistical graphics such as density plots and scatter plots. However, very few of these tools also offer diagnostics for these plots. Users often need to manually inspect and interpret the plots, which can lead to inconsistent conclusions due to varying levels of domain and statistical knowledge. This variability makes it challenging to achieve standardized results from plot diagnostics.

The R package `autovi` addresses this problem by leveraging the visual inference framework to build computer vision models that automatically perform visual statistical testing on residual plots. To make the algorithm and the trained computer vision model widely accessible, we developed a web-based tool called `autovi.web`. This tool provides a user-friendly web interface that allows users to diagnose their residual plots without needing to install any dependencies required by the `autovi` package.

This paper documents the pipeline and the design of the web interface for `autovi.web`. It aims to provide a comprehensive overview of how the tool works, from data upload to the presentation of diagnostic results. The rest of the paper is structured as follows: ...

## Background

The R package `autovi` is designed to provide rejection decisions and $p$-values for testing the null hypothesis that a regression model is correctly specified. To construct a checker with `autovi`, one needs to supply a regression model object—typically an `lm` object representing the result of a linear regression model—and a trained computer vision model compatible with the `Keras` API.

The regression model object is used to extract the fitted values and residuals for creating a residual plot. Additionally, a residual rotation technique is applied to the model object to generate null residuals, which are residuals consistent with the null hypothesis. For a linear regression model, this is conventionally achieved by simulating new random standard normal draws and using them as responses to refit the linear regression model.

Having null plots, which are residual plots consisting of null residuals and the original fitted values, is crucial for constituting a visual test. If the visual test were conducted by humans, a lineup consisting of $m-1$ null plots and one true residual plot would be presented to several observers. Observers would then be asked to select the plot they find most different out of the $m$ residual plots. If many observers correctly identify the true residual plot as the most different, it provides evidence for rejecting the null hypothesis that the model is correctly specified. This is because, under the null hypothesis, the true residual plot should be indistinguishable from the null plots.

Instead of human observers, the visual test in `autovi` is performed by a computer vision model. This model is trained to report the visual signal strength of each individual plot in a lineup. The visual signal strength estimates the divergence of the empirical residual distribution from the ideal residual distribution, effectively measuring the degree of model violations. The higher the visual signal strength, the more evidence there is against the null hypothesis.

The computer vision model's training involves estimating this divergence or distance, which quantifies how much the residuals deviate from what is expected under a correctly specified model. More details about the mathematical derivation and the training process of the computer vision model can be found in the paper by Li et.al. (2024).

Furthermore, the computer vision model used in `autovi` requires a fixed-size 4D tensor as input. The dimensions of this tensor are as follows: the first dimension represents the batch size, the second dimension represents the width of the image, the third dimension represents the height of the image, and the fourth dimension represents the number of channels. The model outputs a numeric vector that represents the visual signal strength for each image in the batch. The computer vision model is also trained with a set of fixed-aesthetic residual plots, which means that the input images must be produced using the same data pipeline that was used for the training data preparation. This consistency is crucial for ensuring that the model can accurately interpret and analyze new data.

A significant portion of our web interface is dedicated to managing this data pipeline. This involves processing the user-provided data to generate input images that conform to the required format for the computer vision model. The pipeline ensures that the residual plots created from the user data match the aesthetics and format of the training data, enabling the model to provide accurate visual signal strength assessments.

<!-- Our web interface simplifies this process for the user by automating the necessary steps to transform their data into the appropriate input format. Users can upload their CSV files, and the interface handles the extraction of residuals, the creation of residual plots, and the formatting of these plots into 4D tensors. This seamless integration allows users to focus on interpreting the results rather than on the technical details of data preparation. -->

## Data Pipeline

In this section, we will describe the entire data pipeline, including handling uploaded data, creating and saving fixed-aesthetic residual plots, loading and transforming images to the desired input format, and predicting visual signal strength.

### Input File Format

As described in Section \ref{background}, the `autovi` package requires a regression model object to initialize the diagnostics. However, it is impractical to ask users to upload an R regression model object for inspection. There are several reasons for this: 

1. **User Complexity**: Saving an R object to the filesystem involves extra steps and requires users to have specific knowledge.
2. **Data Sensitivity**: The regression model object may contain sensitive, non-shareable data.
3. **File Size**: The R object is often unnecessarily large because it contains extra information not needed for diagnostics.

To simplify the process, the web interface instead requests a CSV file. This CSV file should contain at least two columns: `.fitted`, representing the fitted values, and `.resid`, representing the residuals. Additionally, it can contain an optional column `k` to indicate the ID of the residual plot. This is particularly useful if the user wants to evaluate a lineup of residual plots.

Compared to an R model object, a CSV file can be easily generated by various software programs, not just R. CSV files are widely accepted and can be easily viewed and modified using common desktop applications like Excel. CSV files are generally less sensitive than raw data because most information about the predictors is excluded. 

### Plot Drawing and Image Loading

The training data for the computer vision models consist of $32 \times 32$ RGB residual plots. These plots display fitted values on the x-axis and residuals on the y-axis. All labels, including axis texts, are excluded, and no background grid lines are included in the plots. Residual points are drawn in black with a size of 0.5 points, where there are 72.27 points per inch. Additionally, a horizontal red line is drawn at $y = 0$ to help the computer vision model determine if the residual points are uniformly distributed on both sides of the line. The plot is then saved as a PNG file with a resolution of $420 \times 525$ pixels. This resolution mimics a typical lineup residual plot, which has a resolution of $2100 \times 2100$ pixels and is arranged in four rows and five columns.

The uploaded CSV file will be partitioned based on the values in the optional column `k`. If no optional column `k` is present, the entire data set will be used as one partition. Each partition will utilize the plot specifications to generate one residual plot and produce one PNG file.

The saved PNG plot is loaded as an array, where each entry contains a pixel value of the image. This array is then resized to match the input layer shape of the computer vision model, which is $1 \times 32 \times 32 \times 3$. If multiple images are needed for visual signal strength estimation, the arrays can be stacked together to form a larger array with the shape $n \times 32 \times 32 \times 3$, where $n$ is the number of images.

#### Visual Signal Strength Estimation

Finally, the processed image array will be fed into the computer vision model, and returned a vector of visual signal strength which are numerical values always greater than zero.
 
## Software Stack

### Backend

To utilize the `autovi` R package, the server hosting our web interface must have a functional R interpreter. A static HTML page cannot accomplish this task, as it only serves static resources to the client and lacks the capability to execute R code. The alternative option would be WebR, a version of R designed to run within a web browser. However, integrating WebR introduces complexities into the design of the web interface, which we will explore further in Section XXX. Additionally, 
The resizing of the image is originally done by the Python `Pillow` library. To maintain the same data pipeline, we also need a working Python interpreter. Given the required conditions, we have three options: (1) Use a traditional backend like the `Spring` framework written in Java for handling all the income and outcome traffic of the web interface. Meanwhile, install R and Python in the server and call them when needed. (2) Use a Python backend framework like `Flask` so that the `Pillow` library can be used natively. Still, R needs to be installed and correctly configured in the server and called when needed. (3) Use a R backend framework like `Shiny`. This is similar to the second option, but requires to install and configure Python separately.

Option one requires a good understanding




<!-- Thus, we chose to implement the web interface with a shiny server. Shiny server is a backend framework written in R, so it allows us to receive user's input and interactively update the output rendered on the client side using R code.  -->

<!-- We deploy the shiny server using the services provided by Posit, called `shinyapps.io`. It is responsible for reading in the uploaded CSV file with the `readr` R package, splitting the dataset with the `dplyr` R package and drawing the residual plots with the `ggplot2` R package. The resulting PNG files are stored in the temporary directory of the remote machine. -->


<!-- The saved PNG file  -->


### Frontend



### Communications between Software

## Distribute Keras Model Files

## Performance Optimization

