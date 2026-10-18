
> #2; #5; #9: ODEs do not account for expansion in supply when doses drop. There is also need to normalise to 1. I will look into this, I think easy to solve: I am confident the models are OK, but can improve equations and write-up.

There was a need for a more direct explanation/notation of how vaccinations expand as dose shrinks. (Previously we had adjustment of supply explained in words and equations just assumed some flow of daily vaccinations. Now there is a bit of notation, but I tried not to complicate it much.) 

Also a few words of clarification on how we normalise the sizes of compartments: when working with such a model you can either normalise each age group to 1 and remember their relative sizes, or just normalise the whole population to 1.



> #7: because vaccinated recovered people remain in R_a and no vaccination status is recorded for them, the leakage term can sample the same recovered mass repeatedly while that cohort remains active. This may waste capacity more than once per person and can change rollout timing across dosing policies.

I added a bit of a comment on this. The assumption that we do not know who was infected and therefore we vaccinated the recovered, that's by design. The assumption that sometimes (very infrequently) we have someone who is vaccinated, infected, then recovered, then they may be vaccinated again---that's just to keep code simple. We could account for it and it my recollection is that this makes no difference to what we're modeling. 

However, there was a mistake in my code related to this assumption (some minor outflows were not matched by inflows)! So I had to re-run everything.


> #10: several inputs needed to determine the SEIRDV simulations are not reported

I added a small appendix table, which also directs people to the code repository

> #13: the national coverage figures in footnote 14 do not identify a common 80% uptake rate in every age cohort; the footnote itself says uptake was higher in high-risk groups. The simplification may matter for the small estimated gain from age-varying dosing because uptake determines when priority stages end.

I simulated different levels of vaccine hesitancy. I added a footnote where I picked 40% instead of 20% hesitancy (so 60% instead of 80% of each cohort vaccinated) and, as expected, the impacts on results are very small. I don't think we need to provide more info than that.

> #8; #14: some notes about conflicts between reported values; I will investigate, but I would not worry about this, figures and tables are generated from the same source result, so there has to be a sensible explanation

There was a mistake in one of the plots and some corrections in tables, but nothing major, I think maybe in a couple of cases we made a typo in putting together the table.

>#34: update the caption to say what scenario is being demonstrated & check correct values are used

Fig 9 uses uniform full doses, concave dose response, fast-growing epidemic. Fig modified slightly and caption updated, but nothing important to report there.

> #21: immunological noninferiority does not by itself establish equality in the model’s clinical-protection parameter φ. Therefore “same efficacy” and the inference that the full dose must lie far out on a long efficacy plateau are too strong without a validated link from the immune endpoint to clinical protection.

Softened the language a bit.


#45 — Matrajt et al. (2021)

> Refine: the paper is described as using a single age threshold, but Matrajt et al. instead optimise allocation of one and two doses across five age groups; optimal allocations can involve multiple groups rather than one threshold.

#46 — Benest et al. (2020)

> Refine: Benest et al. is cited as evidence that sigmoid dose-response curves fit well, but the paper reportedly found adenoviral-vector vaccine data substantially more consistent with a peaking than a saturating response.


I used LLMs to review these two papers for me as I am pressed for time. But I also remembered these two papers a bit from working on this back in the day.

I think Matrajt et al 2021 can be removed from the citation where it was present, because it's doing something different to us. It's about choosing between 1 and 2 doses, very important work and related to our interest, but just not where it previously appeared in the paper. We do cite it elsewhere in the paper

Benest is a more important case. I think it got lost in edits or something like that, but that is an interesting paper actually arguing that evidence is often consistent with *peaked* curves in particular type of vaccines. There are other papers arguing this, I actually have a mini review of them based on a mini-handbook that I wrote for Coefficient Giving, which I am in the process of making available online. I propose we sidestep this conversation a bit in the paper. We can always link to the chapter, which I will send separately. 

Important to also remember that there is immune response (e.g. "is there a peak in measured antibodies?") and then there is efficacy ("is there a peak in protection from disease?"). These correlate, but are not the same. Again, I don't know if we want to devote space to these discussions? I will send a separate note on this and you can tell me if you'd like to use material from it.


> Refine: the seven-dimensional age-specific problem is nonconvex, so a local nloptr solver may terminate at suboptimal bounds. It recommends multistart procedures, boundary checks, or global-search validation to support the claim that reported optima are global.

I fixed that a bit by adding multiple starting points. A few results may have been affected/improved, but this is only for the age-varying optimisation problem. Nothing major.