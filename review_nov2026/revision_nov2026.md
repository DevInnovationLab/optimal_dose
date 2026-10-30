This document is used to collect Chris's requests, my proposed solution. When done, we will update the paper based on new results, use diff-review to do line-by-line comparison of optimal stretching .tex, then produce a nice HTML which follows the structure of the notes below: cite what Chris suggested verbatim, then cite my solution verbatim, then show the lines diff (OK to also include plot) to show what happened. The goal is to make review user friendly. 







\# Checking the initial values for simulations and updating all results



Chris says:



> You mentioned possibly streamlining the model to have all the initial compartments = 0 except I\\\_a(0), > which we could even make one value across cohorts. S\\\_a(0) is then the residual 1 – I\\\_a(0). I would vote for that simplification.



Solution



* Modify initial conditions for simulations. We set pre-existing immunity in all groups to 0, set E\_1(0) = ... = E\_9(0) = 0.0053, set I\_a(0) = 0 and S\_a(0) = 1 - E\_a(0), with R\_0 = 1.5. These rounded values produce about a 50% attack rate over one year and an epidemic peak at about 3 months without vaccination.
* Re-run all of the simulations with these new settings
* Update the tables/figures, including the overview table with initial parameters for compartments (no need to be age specific anymore!)



Result:



Make sure you print out a diff for the whole results table(s) from Section 6 and you can also print out the main PDF figure of results.









\# Sensitivity analysis



Chris says: 



> Perhaps the main takeaway is that it might be worth putting together a revised sensitivity analysis that is at the same time more systematic yet more streamlined. Have a table of key outcomes only for a variety of sensitivities to R0, ceiling on cohort share that can be reached by vaccines, perhaps I\_a(0), other things, toggling certain model elements (like vaccine leakage from S\_a to R\_a) on or off. If we pull this off, may substitute for the full appendix on slow-growing epidemic and absorb the footnote for max vaccine reach.



> If we are examining the sensitivity to the leakage feature in any event, then fine to leave that feature as is in the baseline specification. It will be less taxing on the reader because we can say “we think it is realistic but don’t worry it doesn’t make much difference”



Solution: 



I propose the following sensitivity analyses:



* compare low-income and high-income age distributions
* increased vaccine hesitancy (we already have this one)
* vary R\_0 and starting exposure jointly to compare attack rates of 30%, 50%, and 70%, with the epidemic peak held at 3 months
* do not vaccinate recovered people (I think it's just an 0-1 switch already in code)
* vary R\_0 and starting exposure jointly to compare epidemic peaks at 2, 3, 4, and 6 months without vaccination, with the attack rate held at about 50%



This is sensitivity against (i.e. each of these changes is compared against) the default choice of 0.1% supply and sigmoid dose-response.



When done, add appendix table which reports optimal uniform dose + benefits for each of these scenarios. Make it nice and readable



That means taking out the appendix dealing with slow-growth epidemic (and references to it in Section 6, or any references to the slow-growth model) and replacing it with sensitivity analysis appendix. We also take out various parts of Section 6, like footnote that talks about increasing vaccine hesitancy (sensitivty analysis). We replace it with short reference to sensitivity analysis, one paragraph, which refers to this new appendix.















