# Appendix to "Software for Automated Residual Plot Assessment: autovi and autovi.web" {#sec-appendix-c}

## Extending the `AUTO_VI` class

The `bandicoot` R package provides a lightweight object-oriented system with Python-like syntax that supports multiple inheritance and incorporates a Python-like method resolution order. The system is inspired by the OOP frameworks implemented in R6 [r6] and Python. In this section, we will provide essential details for extending the `autovi::AUTO_VI` class using `bandicoot`.

In `bandicoot`, a class is declared using the `bandicoot::new_class()` function, where parent classes are provided as positional arguments, and the class name is specified through the `class_name` argument. The output of `bandicoot::new_class()` is an environment with the S3 class `bandicoot_oop`. Printing a `bandicoot` object provides a summary of the object, which can be customized via the `..str..` magic method.






::: {.cell}

```{.r .cell-code}
library(autovi)
EXT_AUTO_VI <- bandicoot::new_class(AUTO_VI, class_name = "EXT_AUTO_VI")
EXT_AUTO_VI
```

::: {.cell-output .cell-output-stderr}

```

```


:::

::: {.cell-output .cell-output-stderr}

```
── <EXT_AUTO_VI class> 
```


:::
:::






An extended class inherits attributes and methods from its parent class(es), so it will behave similarly to them. This can be verified using the built-in `names()` function.






::: {.cell}

```{.r .cell-code}
names(EXT_AUTO_VI)
```

::: {.cell-output .cell-output-stdout}

```
 [1] "..dir.."              "instantiate"          "summary_rank_plot"   
 [4] "del_attr"             "boot_method"          "null_vss"            
 [7] "..class_tree.."       "..instantiated.."     "summary"             
[10] "..str.."              "..repr.."             "likelihood_ratio"    
[13] "plot_resid"           "null_method"          "summary_density_plot"
[16] "..mro.."              "set_attr"             "..methods.."         
[19] "p_value"              "check"                "rotate_resid"        
[22] "lineup_check"         "..method_env.."       "feature_pca_plot"    
[25] "get_data"             "check_result"         "..new.."             
[28] "..bases.."            "plot_pair"            "feature_pca"         
[31] "plot_lineup"          "has_attr"             "summary_plot"        
[34] "..class.."            "auxiliary"            "get_attr"            
[37] "..len.."              "..type.."             "..init.."            
[40] "get_fitted_and_resid" "save_plot"            "boot_vss"            
[43] "vss"                 
```


:::
:::







To register a method for an extended class, you need to pass the class as the first argument and the method as a named argument to the `bandicoot::register_method()` function. Within a method, `self` can be used as a reference to the class or object environment. The following code example overrides the `null_method()` with a function that simulates null residuals from the corresponding normal distribution. This approach differs from the default null residual simulation scheme described earlier. Although less efficient than the default method for linear regression models, it provides an alternative way to simulate null residuals. This method is particularly useful when the fitted model is unavailable, and only the fitted values and residuals are accessible, as discussed in @sec-autovi-web.






::: {.cell}

```{.r .cell-code}
bandicoot::register_method(
  EXT_AUTO_VI, 
  null_method = function(fitted_model = self$fitted_model) {
    data <- self$get_fitted_and_resid(fitted_model)
    residual_sd <- sd(data$.resid)
    data$.resid <- rnorm(nrow(data),
                         sd = residual_sd)
    return(data)
  }
)

EXT_AUTO_VI$null_method(lm(dist ~ speed, data = cars))
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 50 × 2
   .fitted  .resid
     <dbl>   <dbl>
 1   -1.85  -8.35 
 2   -1.85 -13.6  
 3    9.95  -8.14 
 4    9.95  -6.01 
 5   13.9    0.695
 6   17.8   -5.77 
 7   21.7   -9.83 
 8   21.7  -16.4  
 9   21.7    2.72 
10   25.7  -13.9  
# ℹ 40 more rows
```


:::
:::






To create an object in `bandicoot`, you need to call the `instantiate()` method of a class. Alternatively, you can build a convenient class constructor for your class. It is recommended to provide the full list of arguments in the class constructor instead of using `...`, as this makes it easier for integrated development environments (IDEs) like RStudio to offer argument completion hints to the user.






::: {.cell}

```{.r .cell-code}
ext_auto_vi <- function(fitted_model,
                        keras_model = NULL,
                        data = NULL,
                        node_index = 1L,
                        env = new.env(parent = parent.frame()),
                        init_call = sys.call()) {
  EXT_AUTO_VI$instantiate(fitted_model = fitted_model,
                          keras_model = keras_model,
                          data = data,
                          node_index = node_index,
                          env = env,
                          init_call = init_call)
}

ext_auto_vi(lm(dist ~ speed, data = cars))
```
:::
