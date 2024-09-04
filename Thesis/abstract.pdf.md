# Abstract {-}

This work is motivated by the need for an automated approach to diagnose regression models through residual plots with reliability and consistency. While numerical hypothesis tests are commonly used, residual plots remain essential in regression diagnostics because conventional tests are limited to specific types of model departures and tend to be overly sensitive. Visual inference using the lineup protocol offers a less sensitive and more broadly applicable alternative, yet its dependence on human judgment limits scalability. This research addresses these limitations by automating the assessment process.

This research presents three original contributions. The first contribution provides evidence for the effectiveness of visual inference in regression diagnostics through a human subject experiment, demonstrating the benefits of using the lineup protocol for reliable and consistent reading of residual plots. The second contribution introduces a computer vision model to automate the assessment of residual plots, addressing the scalability limitation of the lineup protocol. The third contribution presents an R package and Shiny app, providing a user-friendly interface for analysts to leverage the computer vision model and supporting tools for diagnostic purposes. These contributions advance the field of artificial intelligence for data visualization, enabling more efficient and accurate regression diagnostics.

# Declaration {-}

I hereby declare that this thesis contains no material which has been accepted for the award of any other degree or diploma at any university or equivalent institution and that, to the best of my knowledge and belief, this thesis contains no material previously published or written by another person, except where due reference is made in the text of the thesis.

This thesis includes one original papers published in a peer reviewed journal and two unpublished papers. The core theme of the thesis is "automated reading of residual plots". The ideas, development and writing up of all the papers in the thesis were the principal responsibility of myself, the student, working within the Department of Econometrics and Business Statistics under the supervision of Professor Dianne Cook, Dr Emi Tanaka (Australian National University), Assistant Professor Susan VanderPlas (University of Nebraska–Lincoln) and Assistant Professor Klaus Ackermann.

The inclusion of co-authors reflects the fact that the work came from active collaboration between researchers and acknowledges input into team-based research. In the case of [Chapter 2](#sec-first-paper), my contribution to the work involved the following:






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
\bottomrule
\end{tabular}
\endgroup{}
\end{table}


:::
:::







Chapters 3, *Automated Assessment of Residual Plots with Computer Vision Models*, and Chapter 4, *Software for Automated Residual Plot Assessment: autovi and autovi.web*, are planned for submission to peer-reviewed journals.

\clearpage

To ensure the clarity and coherence of the written content, artificial intelligence tools were employed to assist in smoothing and refining the language throughout the thesis.

<!-- **The thesis is written in Australian spelling, except for Chapters 3 and 4, which use American spelling as specified by the publication venue.** -->

I have not renumbered sections of submitted or published papers in order to generate a consistent presentation within the thesis.

**Student name**: Weihao Li

**Student signature**: 

**Date**: 4th September 2024 

I hereby certify that the above declaration correctly reflects the nature and extent of the student’s and co-authors’ contributions to this work. In instances where I am not the responsible author I have consulted with the responsible author to agree on the respective contributions of the authors.

**Main Supervisor name**: Dianne Cook

**Main Supervisor signature**:

**Date**: 4th September 2024

