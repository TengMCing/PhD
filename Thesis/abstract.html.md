# Abstract {-}

This work is motivated by the need for an automated approach to diagnose regression models through residual plots with reliability and consistency. While numerical hypothesis tests are commonly used, residual plots remain essential in regression diagnostics because conventional tests are limited to specific types of model departures and tend to be overly sensitive. This research builds on a method called the lineup protocol, a statistical visualization approach that embeds a data plot among null plots to compare patterns arising by chance with those observed in the data. This process is part of visual inference, where human judgment is used to make statistical inferences from data visualizations. However, the reliance on human judgment in visual inference poses challenges for scalability and consistency.

To overcome these challenges, this research presents three original contributions. The first contribution provides evidence for the effectiveness of visual inference in regression diagnostics through a human subject experiment, demonstrating the benefits of using the lineup protocol for reliable and consistent reading of residual plots. The second contribution introduces a computer vision model to automate the assessment of residual plots, addressing the scalability limitation of the lineup protocol. The third contribution presents an R package and Shiny app, providing a user-friendly interface for analysts to leverage the computer vision model and supporting tools for diagnostic purposes. These contributions advance the field of artificial intelligence for data visualization, enabling more efficient and accurate regression diagnostics.

# Declaration {-}

I hereby declare that this thesis contains no material which has been accepted for the award of any other degree or diploma at any university or equivalent institution and that, to the best of my knowledge and belief, this thesis contains no material previously published or written by another person, except where due reference is made in the text of the thesis.

This thesis includes one original papers published in a peer reviewed journal and two unpublished papers. The core theme of the thesis is "automated reading of residual plots". The ideas, development and writing up of all the papers in the thesis were the principal responsibility of myself, the student, working within the Department of Econometrics and Business Statistics under the supervision of Professor Dianne Cook, Dr Emi Tanaka (Australian National University), Assistant Professor Susan VanderPlas (University of Nebraska–Lincoln) and Assistant Professor Klaus Ackermann.

The inclusion of co-authors reflects the fact that the work came from active collaboration between researchers and acknowledges input into team-based research. In the case of [Chapter 2](#sec-first-paper), my contribution to the work involved the following:






::: {.cell}
::: {.cell-output-display}

`````{=html}
<table class="table" style="font-size: 10px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:right;font-weight: bold;text-align: left;"> Chapter </th>
   <th style="text-align:left;font-weight: bold;text-align: left;"> Publication title </th>
   <th style="text-align:left;font-weight: bold;text-align: left;"> Status </th>
   <th style="text-align:left;font-weight: bold;text-align: left;"> Student contribution </th>
   <th style="text-align:left;font-weight: bold;text-align: left;"> Co-authors contribution </th>
   <th style="text-align:left;font-weight: bold;text-align: left;"> Coauthors are Monash students </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;width: 1.2cm; "> 2 </td>
   <td style="text-align:left;width: 3cm; "> A Plot is Worth a Thousand Tests: Assessing Residual Diagnostics with the Lineup Protocol </td>
   <td style="text-align:left;width: 3.5cm; "> Published in the Journal of Computational and Graphical Statistics </td>
   <td style="text-align:left;width: 2.5cm; "> 80%  Concept, Analysis, Software, Writing </td>
   <td style="text-align:left;width: 2.4cm; "> D. Cook 10%,  
 E. Tanaka 5%, 
 S. VanderPlas 5 </td>
   <td style="text-align:left;width: 1.3cm; "> |No </td>
  </tr>
</tbody>
</table>

`````

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

