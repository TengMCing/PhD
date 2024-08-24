# Abstract {-}

This work is motivated by the need for an automated approach to diagnose regression models through residual plots with reliability and consistency. While numerical hypothesis tests are commonly used, residual plots remain essential in model diagnosis because conventional tests are limited to specific types of model departures and tend to be overly sensitive. Visual inference using the lineup protocol offers a less sensitive and more broadly applicable alternative, yet its dependence on human judgment limits scalability. This research addresses these limitations by automating the assessment process.

This research presents three original contributions. The first contribution ([Chapter 2](#sec-first-paper)) provides evidence for the effectiveness of visual inference in regression diagnostics through a human subject experiment, demonstrating the benefits of using the lineup protocol for reliable and consistent reading of residual plots. The second contribution ([Chapter 3](#sec-second-paper)) introduces a computer vision model to automate the assessment of residual plots, addressing the scalability limitation of the lineup protocol. The third contribution ([Chapter 4](#sec-third-paper)) presents an R package and Shiny app, providing a user-friendly interface for analysts to leverage the computer vision model and supporting tools for diagnostic purposes. These contributions advance the field of artificial intelligence for data visualization, enabling more efficient and accurate regression diagnostics.

# Declaration {-}

I hereby declare that this thesis contains no material which has been accepted for the award of any other degree or diploma at any university or equivalent institution and that, to the best of my knowledge and belief, this thesis contains no material previously published or written by another person, except where due reference is made in the text of the thesis.

This thesis includes one original paper published in a peer reviewed journal and two unpublished papers.

The inclusion of co-authors reflects the fact that the work came from active collaboration between researchers and acknowledges input into team-based research. In the case of [Chapter 2](#sec-first-paper) and [Chapter 4](#sec-third-paper), my contribution to the work involved the following:






::: {.cell}
::: {.cell-output-display}
\begin{table}[!h]
\centering\begingroup\fontsize{10}{12}\selectfont

\begin{tabular}{>{\raggedleft\arraybackslash}p{1.2cm}>{\raggedright\arraybackslash}p{3cm}>{\raggedright\arraybackslash}p{3.5cm}>{\raggedright\arraybackslash}p{2.5cm}>{\raggedright\arraybackslash}p{2.4cm}>{\raggedright\arraybackslash}p{1.3cm}}
\toprule
\multicolumn{1}{>{\raggedright\arraybackslash}p{1.2cm}}{\textbf{Chapter}} & \multicolumn{1}{>{\raggedright\arraybackslash}p{3cm}}{\textbf{Publication title}} & \multicolumn{1}{>{\raggedright\arraybackslash}p{3.5cm}}{\textbf{Status}} & \multicolumn{1}{>{\raggedright\arraybackslash}p{2.5cm}}{\textbf{Student contribution}} & \multicolumn{1}{>{\raggedright\arraybackslash}p{2.4cm}}{\textbf{Co-authors contribution}} & \multicolumn{1}{>{\raggedright\arraybackslash}p{1.3cm}}{\textbf{Coauthors are Monash students}}\\
\midrule
2 & A Plot is Worth a Thousand Tests: Assessing Residual Diagnostics with the Lineup Protocol & Published in the Journal of Computational and Graphical Statistics & 80\%  Concept, Analysis, Software, Writing & D. Cook 10\%,  
 E. Tanaka 5\%, 
 S. VanderPlas 5\% & No\\
4 & Software for Automated Residual Plot Assessment: autovi and autovi.web & The R package autovi on CRAN & 80\% Concept, Analysis, Software, Writing & D. Cook 10\%,  
 E. Tanaka 5\%, 
 S. VanderPlas 2.5\%, K. Ackermann 2.5\% & No\\
\bottomrule
\end{tabular}
\endgroup{}
\end{table}


:::
:::






Chapter 3, *Automated Assessment of Residual Plots with Computer Vision Models* is to be submitted for the Journal of Computational and Graphical Statistics. 


<!-- **The thesis is written in Australian spelling, except for Chapters 3 and 4, which use American spelling as specified by the publication venue.** -->

I have not renumbered sections of submitted or published papers in order to generate a consistent presentation within the thesis.

**Student name**: Weihao Li

**Student signature**: 

**Date**: 26th August 2024 

I hereby certify that the above declaration correctly reflects the nature and extent of the student’s and co-authors’ contributions to this work. In instances where I am not the responsible author I have consulted with the responsible author to agree on the respective contributions of the authors.

**Main Supervisor name**: Dianne Cook

**Main Supervisor signature**:

**Date**: 26th August 2024

