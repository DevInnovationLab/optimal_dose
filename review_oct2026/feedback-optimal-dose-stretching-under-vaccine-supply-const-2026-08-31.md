# Optimal Dose Stretching Under Vaccine Supply Constraints

**Date**: 8/31/2026, 3:40:01 PM
**Domain**: social_sciences/economics
**Taxonomy**: academic/research_paper
**Filter**: Active comments

---

## Overall Feedback

**Capacity constraints in the epidemiological model**

In Section 6.1, the vaccination flows are specified as $q v_a(t)$, which is independent of the dose strength $x_a$. Here, $q$ is calibrated as the share of the population that can receive full doses per day, and $x_a$ appears only inside the efficacy function $\phi(x_a)$.


Equations (26)–(32) as written imply that lowering a dose reduces efficacy without accelerating population coverage. Because accelerating coverage is the core mechanism of dose stretching, the model requires an explicit antigen-flow constraint. Formulating the vaccination flow proportionally to $q/x_a$ and detailing the accounting for age-varying doses will fully align the dynamic equations with the optima reported in Table 1 and Figures 10–11.

**Proof mechanics and global conditions**

The paper characterizes the optimal policy and comparative statics using first-order approaches. Proposition 2 differentiates the largest element of an argmax as though it represents a unique, smooth branch with a strictly negative second derivative. Furthermore, Lemma 8 guarantees the short-supply maximizer only for sufficiently small $Q$, whereas Propositions 2 and 6 deploy this maximizer universally.


Because the objective function for the nonconcave sigmoid case is not globally concave, the KKT conditions invoked for Proposition 6 are necessary rather than sufficient. The supporting proofs also contain integral identities in Lemmas 7 and 8 that omit the chain-rule factor $\phi(x)$ that arises when differentiating $B(n\phi(x))$ with respect to $n$. Establishing these characterizations securely will require either explicitly proving unique global solutions and branch stability or circumscribing the propositions to ranges of $Q$ where smooth local selections hold.

**Extrapolation and numerical optimization**

The quantitative findings rely on dose-response curves anchored by $\phi(0.5)=0.8$, $\phi(1)=0.95$, $\phi'(1)=0$, and the origin. Some of the optimal interventions in Table 1 dictate doses as low as 3–7% of a full dose. At these levels, the efficacy values are entirely extrapolations dictated by the chosen functional forms. Expanding the sensitivity analysis to encompass uncertainty over low-dose slopes, threshold locations, and plateau shapes will ground the quantitative conclusions more firmly.


In a related numerical matter, Section 6.2 notes the use of the nloptr package for the age-specific optimization. Because this seven-dimensional problem is nonconvex, local solvers can terminate at suboptimal bounds. Including diagnostics—such as multistart procedures, boundary checks, or global-search validations—will certify that the reported optima represent true global maxima.

**Cost parameters and the supply-scarcity reversal**

The paper identifies a counterintuitive regime where tighter supply constraints lead to stronger optimal doses. This reversal relies on the costly-vaccination mechanism—specifically, convex side-effect costs and a fixed administration cost threshold. Because Section 6 sets generalized costs to zero ($g(x)=0$), the quantitative model leaves this theoretical mechanism unassessed under simulated epidemic conditions.


In addition, the text in Section 7 states that this reversal requires fixed administration costs to be "sufficiently high," but Proposition 5 shows that the derivative $d\bar{x}^s(Q)/dQ < 0$—indicating stronger doses as $Q$ falls—arises when $k < \hat{k}$, meaning fixed costs are sufficiently low. Reconciling this sign interpretation and either quantifying the mechanism under specific cost scenarios or explicitly framing it as an unquantified theoretical dynamic will clarify the policy takeaway.

**Horizons and the mortality estimand**

The headline finding that fractional dosing can increase averted deaths by "as much as 40%" warrants precision regarding the estimand. Equation (35), defined as $[AD(x^p) - AD(X)] / AD(x^p)$, computes the fraction of deaths remaining under full dosing that fractional dosing eliminates, rather than the percentage increase in deaths averted relative to the full-dose program. For example, the 0.1% sigmoid entries in Table 1 yield 17.6% under equation (35), which translates to a 37.5% increase in deaths averted.


Additionally, the simulation evaluates all deaths at a fixed 365-day horizon. Under settings like $\mathscr{R}_0 = 1.1$, an effective vaccination campaign can push infections beyond the one-year window, potentially truncating the true outcome differences. Verifying long-horizon convergence will ensure that the reported mortality differences represent permanent epidemic reductions rather than artifacts of the simulation cutoff.

**Status**: [Pending]

---

## Detailed Comments (47)

### 1. Population constraint is dropped in short-supply step

**Status**: [Pending]

**Quote**:
> Therefore, the pair $\left(\bar{n}^{0}, \bar{x}^{0}\right)$ is a solution to the planner's problem unless $\bar{n}^{0} \bar{x}^{0}>Q$. In that case, the capacity constraint binds. Then, the remaining problem is the same as the short-supply benchmark. We saw above that the largest solution $\bar{x}^{s}(Q)$ relaxes omitted constraints to the extent possible. Hence, the solution when $\bar{n}^{0} \bar{x}^{0}>Q$ is $x^{*}=\bar{x}^{s}(Q)$ and $n^{*}=Q / \bar{x}^{s}(Q)$. Q.E.D.

**Feedback**:
The short-supply benchmark omits the population constraint: after imposing $nx=Q$, the original problem still requires $x\geq Q/N$. Selecting the largest short-supply maximizer only minimizes $Q/x$ within that relaxed solution set; it does not establish $Q/\bar{x}^s(Q)\leq N$. The proof must either establish this feasibility condition or analyze the case in which both constraints bind. It also does not derive the proposition’s stated min/max formula, which requires additional ordering relations between $\bar{x}^s(Q)$ and $\bar{x}^0$.

---

### 2. Section 6.3’s acceleration mechanism is absent from the ODEs

**Status**: [Pending]

**Quote**:
> Table 1 presents the results for various levels of vaccine capacity and for both shapes of the dose-response function. Focus first on the results for the benchmark supply (0.1\% of the population vaccinated each day) and sigmoid dose-response function. In that case, full doses avert 32\% of the deaths under no vaccination. To stretch such a modest capacity, the optimal uniform dose ends up being about half of a full dose. Distributing these smaller doses more quickly allows the planner to avert 44\% of deaths.

**Feedback**:
The stated SEIRDV system does not implement the coverage-acceleration mechanism underlying the calibration results. Its vaccination flow is $qv_a(t)$, independent of $x_a$, while dose strength only changes efficacy. Given $g(x)=0$ and efficacy increasing on $[0,1]$, full dosing would therefore dominate fractional dosing under the displayed equations. If $q$ denotes full-dose-equivalent antigen capacity, recipient flow and cohort-completion times must depend on dose strength, for example through $q/x_a$; without such a relationship, the reported fractional-dose optima do not follow from the specified model.

---

### 3. Global-optimality gap in Proposition 6 proof

**Status**: [Pending]

**Quote**:
> Suppose for the sake of contradiction that neither constraint (3) or (4) binds. Then $\lambda^{*}=\mu^{*}=0$. Substituting these values into (A84) yields $B^{\prime}\left(n^{*} \phi\left(x^{*}\right)\right) \phi\left(x^{*}\right)=g\left(x^{*}\right)$. Rearranging,

$$
\begin{aligned}
1 & =B^{\prime}\left(n^{*} \phi\left(x^{*}\right)\right) \frac{\phi\left(x^{*}\right)}{g\left(x^{*}\right)} \\
& =B^{\prime}\left(n^{0} \phi\left(x^{0}\right)\right) \frac{\phi\left(x^{0}\right)}{g\left(x^{0}\right)} \\
& =B^{\prime}\left(n^{0} \phi\left(x^{0}\right)\right) \frac{\phi\left(\bar{x}^{0}\right)}{g\left(\bar{x}^{0}\right)}
\end{aligned}
$$

Equation (A88) follows since $\left(n^{*}, x^{*}\right)$ must be one of the solutions $\left(n^{0}, x^{0}\right)$ to the unconstrained problem (8).

**Feedback**:
Equation (A88) is not justified by slackness and the necessary KKT conditions alone. Those conditions make $(n^*,x^*)$ a stationary point of the unconstrained problem, but the paper has not shown that every such point globally maximizes that problem; the nonconcavity in $x$ leaves open a constrained optimum that is locally unconstrained while a superior unconstrained point violates a distant constraint. A separate global-dominance argument or stronger shape condition is needed for the benchmark identification and the ensuing contradiction.

---

### 4. Proposition 2 needs regularity and a Q domain

**Status**: [Pending]

**Quote**:
> It is natural to think that a reduction in $Q$ would reduce $\bar{x}^{s}(Q)$ : a tighter supply constraint would be accommodated by smaller fractional doses. In fact, the comparative-statics is more complicated: $\bar{x}^{s}(Q)$ may be increasing, constant, or decreasing in $Q$. The next proposition provides a sufficient statistic for the direction of the comparative-static effect, depending on whether generalized cost is more or less elastic than efficacy where efficacy is unit elastic. ${ }^{8}$

Proposition 2. $\operatorname{sgn}\left(d \bar{x}^{s}(Q) / d Q\right)=\operatorname{sgn}\left(\eta_{\phi}\left(\bar{x}^{e}\right)-\eta_{g}\left(\bar{x}^{e}\right)\right)=\operatorname{sgn}\left(1-\eta_{g}\left(\bar{x}^{e}\right)\right)$.
We have accorded this comparative-static result the status of a proposition since, as we will see in the next subsection, it dictates the shape of the overall planner optimum at low levels of $Q$.

**Feedback**:
Proposition 2 requires additional qualification. Lemma 8 establishes a finite largest maximizer only for sufficiently small $Q$, while differentiating $\bar{x}^s(Q)$ requires a locally unique, nondegenerate interior optimum. The displayed sign result is therefore established along smooth branches of strict maximizers, but not as stated for the globally selected largest maximizer at ties, degenerate optima, or unrestricted values of $Q$.

---

### 5. Section 6.1 vaccination flow omits dose strength

**Status**: [Pending]

**Quote**:
> $$
\begin{aligned}
\dot{S}_{a}(t) & =-\lambda_{a}(t) S_{a}(t)-q v_{a}(t)\left[\frac{S_{a}(t)}{S_{a}(t)+R_{a}(t)}\right] \\
\dot{E}_{a}(t) & =\lambda_{a}(t)\left[S_{a}(t)+N_{a}(t)\right]-\varepsilon_{a} E_{a}(t) \\
\dot{I}_{a}(t) & =\varepsilon_{a} E_{a}(t)-\xi_{a} I_{a}(t) \\
\dot{R}_{a}(t) & =\left(1-\mu_{a}\right) \xi_{a} I_{a}(t) \\
\dot{D}_{a}(t) & =\mu_{a} \xi_{a} I_{a}(t) \\
\dot{P}_{a}(t) & =q v_{a}(t) \phi\left(x_{a}\right)\left[\frac{S_{a}(t)}{S_{a}(t)+R_{a}(t)}\right]-\psi_{a} P_{a}(t) \\
\dot{N}_{a}(t) & =q v_{a}(t)\left[1-\phi\left(x_{a}\right)\right]\left[\frac{S_{a}(t)}{S_{a}(t)+R_{a}(t)}\right]+\psi_{a} P_{a}(t)-\lambda_{a}(t) N_{a}(t) .
\end{aligned}
$$

**Feedback**:
The vaccination-flow equations hold $q$ fixed and include $x_a$ only through efficacy. Yet supply is subsequently measured as full-dose antigen capacity, so fractional dosing should increase the number vaccinated per unit time—for a uniform dose, the rate would ordinarily be proportional to $q/x$. Without an explicitly defined dose-dependent throughput, especially for age-varying doses, the displayed system makes fractional doses less effective without accelerating coverage and therefore cannot generate the reported mechanism. If the simulations apply such a supply-to-throughput mapping, it is missing from the model specification.

---

### 43. Gans (2022) does not study robust policy under uncertainty

**Status**: [Pending]

**Quote**:
> Recent work has studied optimal subsidy policy (Goodkin-Gold et al., 2024), the relative merits of vaccines versus therapeutics (LaTorre, Malik, and Marsiglio, 2020; Toxvaerd and Rowthorn, 2022), the substitutability between vaccination and social distancing (Atkeson, 2021; Avery, 2024), and the formation of robust policy in the face of model and parametric uncertainty (Manski, 2020; Gans, 2022).

**Feedback**:
The citing sentence groups Gans (2022) with Manski (2020) as studying "the formation of robust policy in the face of model and parametric uncertainty." However, Gans (2022) actually studies how to create a tractable behavioral epidemiological model, proposing that the effective reproduction number trending toward 1 (R=1) in equilibrium can be used as a mathematical shortcut for modeling endogenous social distancing. The paper does not address model or parametric uncertainty, nor does it discuss robust policy formation. It appears to have been misattributed to this category.

---

### 44. Dalton et al. (2023) efficacy rates misattributed to dose volume

**Status**: [Pending]

**Quote**:
> Studies found that the lower dose retained substantial efficacy, estimating a 75% effectivenss against infection compared to 86% for the full dose (Dalton et al., 2023).

**Feedback**:
The submission materially misrepresents the findings of Dalton et al. (2023) by confusing the *number of doses* with the *volume/route of the dose*. The study found a 75% effectiveness for partial vaccination (one dose) compared to 86% for full vaccination (two doses). It did not find that a lower one-fifth intradermal dose had 75% effectiveness compared to 86% for a full subcutaneous dose; in fact, the study found that vaccine effectiveness was comparable across both administration routes.

---

### 45. Matrajt et al. (2021) modeled multiple age groups, not a single threshold

**Status**: [Pending]

**Quote**:
> The few previous studies that allowed any variation in dosing by age considered a single age threshold between those receiving full doses and those receiving an exogenous stretched dose (Wu et al., 2016; Matrajt et al., 2021; Leung, Eaton, and Matrajt, 2022).

**Feedback**:
The claim states that Matrajt et al. (2021) "considered a single age threshold" for variation in dosing. This misrepresents the study's methodology. The authors actually collapsed the population into five distinct age groups (0-19, 20-49, 50-64, 65-74, and 75+) and used optimization algorithms to determine the optimal allocation of one and two doses across these multiple groups. The resulting optimal strategies were often more complex than a single age threshold, such as simultaneously prioritizing two doses for both younger high-transmission adults (20-49) and high-risk adults (65 and older).

---

### 46. Benest et al. (2020) contradicts sigmoid dose-response claim

**Status**: [Pending]

**Quote**:
> Empirical estimates of dose-response functions find a sigmoid shape fits the data well in both animal and human studies (Benest et al., 2020; de Jonge et al., 2020; Roozendaal et al., 2021).

**Feedback**:
The cited paper actively contradicts the claim that a sigmoid (saturating) shape fits dose-response functions well. Benest et al. specifically analyzed adenoviral vector vaccines and found that the data was actually "five times more likely to be peaking than saturating," explicitly noting that this peaking pattern is different from the typical expectation of an S-shaped (sigmoid) response.

---

### 6. Costly-case comparative static needs regularity

**Status**: [Pending]

**Quote**:
> While a model that abstracts from side effects (along with other costs of administering stronger doses and covering more of the population) provides a useful starting point for the analysis, our main analysis builds those costs back in. With a concave dose-response function, we continue to find that the optimal fractional dose is weakly increasing in vaccine supplies. With a sigmoid function, we provide necessary and sufficient conditions for there to be a region of extremely scarce supplies in which further decreases in supply leads the optimal fractional dose to be stronger, not weaker. The intuition for this surprising result is that when supplies are extremely scarce, protecting vaccinated individuals becomes the paramount concern since limited vaccine supplies will lead to soaring infection rates. Concerns that administering a more potent dose to them might entail worse side effects become relatively less important.

**Feedback**:
The necessary-and-sufficient costly-case comparative static is not established under the stated assumptions. The paper permits multiple short-supply maximizers and defines $\bar{x}^s(Q)$ as the largest one, but Proposition 2 differentiates this selection without establishing local uniqueness, differentiability, or a strict second-order condition. At a tie where global maximizers switch, or at a degenerate optimum with zero second derivative, $d\bar{x}^s(Q)/dQ$ need not exist. The stated sign result therefore applies directly only along a regular differentiable maximizing branch unless a separate monotone-selection result or additional regularity is established.

---

### 7. Section 6.1 cannot track vaccinated recoveries

**Status**: [Pending]

**Quote**:
> Possible imperfections in the vaccine campaign are captured via three model assumptions. First, as mentioned, we assume that the vaccine is imperfectly effective, i.e., $\phi\left(x_{a}\right)<1$. Second, we assume that recovered and susceptible individuals cannot be distinguished, so both compartments end up being vaccinated. Since recovered individuals already have natural immunity, the vaccine is effectively wasted on them. This imperfection explains the factor in square brackets in equation (26), the share left for the susceptible compartment after the "leakage" to the recovered compartment. Third, we assume that loss of vaccine-induced immunity is unobservable, so the move from $P_{a}$ to $N_{a}$ cannot be prevented by revaccinating the individual.

**Feedback**:
The leakage term repeatedly samples $R_a$ because vaccinated recovered people neither leave that compartment nor acquire a recorded vaccination status. The same recovered mass can consequently consume vaccine multiple times while its cohort remains active, contrary to the description of vaccinating each willing cohort member once. Because this wasted capacity affects rollout timing and may vary with campaign duration and dose strength, the omission can distort comparisons between full, uniform fractional, and age-varying dosing.

---

### 8. Figure A3 conflicts with dose-stretching capacity

**Status**: [Pending]

**Quote**:
> ![](/documents/16d5bccc-33a3-4977-a27f-a71108970c06/images/image_013.jpg)
Figure A2: Deaths Averted Moving from Full to Fractional Dosing in a Slow-Growing Epidemic. Reprises results from Figure 10, reducing $\mathscr{R}_{0}$ from 2 to 1.1. See that figure for additional notes.

![](/documents/16d5bccc-33a3-4977-a27f-a71108970c06/images/image_014.jpg)
Figure A3: Optimal Age-Varying Fractional Doses in a Slow-Growing Epidemic. Reprises results from Figure 11, reducing $\mathscr{R}_{0}$ from 2 to 1.1. See that figure for additional notes.

**Feedback**:
Figure A3's concave 0.01% series appears inconsistent with the stated capacity accounting. Its sole plotted point indicates a dose near 0.01 for the 80+ cohort, although 365 days of supply at 0.01% of the population per day provides \$0.0365N$ full-dose equivalents. Vaccinating even 80% of the entire population at dose 0.01 would use only \$0.008N$, so the campaign should at least proceed beyond the oldest cohort while the slow epidemic remains active. The omission of every younger cohort therefore requires verification of the dose-to-coverage conversion or the figure's series.

---

### 9. Section 6.1 leaves infection-rate units unresolved

**Status**: [Pending]

**Quote**:
> Susceptible individuals, in compartment $S_{a}(t)$, become infected at rate $\lambda_{a}(t)$, which depends on contacts with infectious individuals in various cohorts:

$$
\lambda_{a}(t)=\beta \sum_{a^{\prime}=1}^{A} c_{a, a^{\prime}} I_{a^{\prime}}(t) .
$$

Parameter $\beta$ captures the virus' transmissibility; $c_{a, a^{\prime}}$ is an element of the contact matrix, equal to the number of contacts made by an individual in cohort $a$ with members of cohort $a^{\prime}$.

**Feedback**:
The ODE system does not specify a normalization under which both the transmission and vaccination terms have the stated units. If $I_{a'}$ is prevalence within cohort $a'$, the force-of-infection expression is conventional, but subtracting $q$—defined as a share of the total population per unit time—from a within-cohort state requires an age-specific population conversion. If the compartments are masses or total-population shares, the force of infection instead requires cohort-size normalization unless that normalization is already embedded in $c_{a,a'}$. This matters for the model’s age-specific transmission patterns and reproducibility.

---

### 10. Several dynamic calibration inputs remain unspecified

**Status**: [Pending]

**Quote**:
> We calibrate model parameters to the outcomes of initial clinical trials of the first effective Covid19 vaccines and mass vaccination campaigns that began in late 2020 and continued through 2021, when all countries faced shortage of vaccines. Our goal is to guide the selection of roughly plausible parameters. Providing an accurate portrayal of the Covid-19 pandemic is beyond the scope of this exercise for several reasons. First, outcomes varied widely across countries; in taking the global average for a parameter, we may fail to reflect the experience in any given region. Second, the all-or-nothing nature of the vaccine in the model allows for a single notion of the efficacy of the vaccine, which works equally well to prevent infection, disease, severe disease, or death. In reality, Covid-19 vaccines were more effective at preventing deaths and hospitalizations than preventing transmission, and this distinction only grew with emergence of variants, which we do not model. Most importantly, our specification of the SEIRDV model has a single epidemic outbreak. This may not be unrealistic if interpreted as applying to the first wave caused by the ancestral strain of Covid-19 but becomes increasingly unrealistic with the emergence of Covid-19 variants, leading
to infection cycles, which the model is not designed to capture. ${ }^{10}$

**Feedback**:
The dynamic calibration does not report several inputs required to determine the SEIRDV simulations, including cohort population shares and initial compartment values, the exposed- and infectious-exit rates $\varepsilon_a$ and $\xi_a$, and the vaccine-immunity waning rates $\psi_a$. These inputs affect epidemic timing, prioritized rollout, and the mortality objective; citing the earlier model and providing code aids replication but does not make the article’s parameterization self-contained.

---

### 47. Goodkin-Gold et al. (2024) explicitly notes its model lacks simple closed-form solutions

**Status**: [Pending]

**Quote**:
> While some simple compartmental models admit closed-form solutions (see, e.g., Goodkin-Gold et al., 2024), complex models like the one here-with more compartments and heterogeneous cohorts-have no known analytical solutions.

**Feedback**:
Goodkin-Gold et al. (2024) is misplaced as an example of a model that admits closed-form solutions. The paper explicitly states that "no closed-form solution exists" for its model's equilibrium state, and contrasts its approach with a 2022 companion paper by the same authors by noting that "unlike here, steady states in the companion paper have simple closed-form expressions." The citation likely intended to point to that 2022 companion paper instead.

---

### 11. Peaked curves conflict with the global shape assumptions

**Status**: [Pending]

**Quote**:
> ### 5.1. Peaked Efficacy

In the model analyzed thus far, we took efficacy to be an increasing function over its whole domain. Marginal efficacy remained positive for any finite dose, no matter how large. In this subsection, we consider an alternative model of peaked efficacy. In this alternative illustrated in Figure 5, efficacy increases up to a peak, denoted $x^{p}$, and decreases for larger doses.

We have several motives for analyzing peaked efficacy. First, it is consistent with some vaccinology studies. Experiments with animal models found statistically significant evidence of a peak in the dose-response functions (Pompano et al., 2014; Rhodes et al., 2016; Billeskov et al., 2018). Second, we will adopt peaked efficacy functions in our calibrations.

**Feedback**:
The peaked-efficacy extension does not state the revised global assumptions on $\phi$. A bounded function on $[0,\infty)$ that decreases after an interior peak cannot remain concave thereafter, so it cannot retain the original global concave or single-inflection sigmoid definitions. Proposition 7 consequently requires assumptions ensuring that the earlier per-unit-efficacy results remain valid on the relevant pre-peak domain.

---

### 12. Global concavity conflicts with peaked efficacy in 5.2

**Status**: [Pending]

**Quote**:
> To integrate uncertainty and peaked efficacy in the same model, assume for all $\theta \in(0, \infty)$, there exists $x^{p}(\theta)>0$ such that $\phi_{x}\left(x^{p}(\theta), \theta\right)=0$. Totally differentiating with respect to $\theta$ and rearranging yields

$$
\frac{d x^{p}(\theta)}{d \theta}=-\frac{\phi_{x \theta}\left(x^{p}(\theta), \theta\right)}{\phi_{x x}\left(x^{p}(\theta), \theta\right)}>0 .
$$

Since $\phi_{x x}<0$, we have $\phi_{x}(x, \theta)>0$ for all $x \in\left[0, x^{p}(\theta)\right)$ and $\phi_{x}(x, \theta)<0$ for all $x>x^{p}(\theta)$.

**Feedback**:
Subsection 5.2 imposes mutually inconsistent global assumptions. For fixed $\theta$, if $\phi_{xx}<0$ on $[0,\infty)$ and $\phi_x(x^p(\theta),\theta)=0$, then at any $x_0>x^p(\theta)$, $c=\phi_x(x_0,\theta)<0$, and strict concavity implies $\phi_x(x,\theta)\leq c$ for every $x\geq x_0$. Consequently, $\phi(x,\theta)\leq\phi(x_0,\theta)+c(x-x_0)$ and eventually becomes negative, contradicting its interpretation as an efficacy probability in $[0,1]$. Thus, as formally specified over $x\geq0$, the function class underlying this extension is empty.

---

### 13. Footnote 14 does not support uniform cohort uptake

**Status**: [Pending]

**Quote**:
> ${ }^{14}$ Overall, $80 \%$ was the upper limit of vaccination coverage at the end of the pandemic (by 2023 United States reached 69\% fully vaccinated, Germany 76\%, United Kingdom 75\%). In 2021 it was typical for countries with good supply to reach over 80\% in highest risk groups and much lower in general population. This pattern differed considerably across countries (by 2023 Nigeria reached 30\%, Ethiopia 35\%, Democratic Republic of Congo below 10\%; all figures according to Our World in Data (2024)).

**Feedback**:
The uniform 80% cohort-uptake assumption is not identified by the aggregate national coverage figures in footnote 14, and the footnote itself notes higher uptake in high-risk groups than in the general population. This is a defensible simplification, but the reported small gain from age-varying dosing may be sensitive to it because cohort-specific uptake determines when age-priority stages end and which cohorts are reached within the 365-day simulation.

---

### 14. Table A1 and Figure A2 disagree at low supply

**Status**: [Pending]

**Quote**:
> | Concave Dose Response |  |  |  |  |  |  |
| 0.01\% | 100\% | 3\% | Fig. A3 | 6\% | 23\% | 23\% |
| 0.1\% | 100\% | 15\% | Fig. A3 | 43\% | 65\% | 67\% |
| 1\% | 100\% | 55\% | Fig. A3 | 85\% | 87\% | 87\% |
| 10\% | 100\% | 87\% | Fig. A3 | 91\% | 91\% | 91\% |


Notes: Reprises results from Table A1, reducing $\mathscr{R}_{0}$ from 2 to 1.1. See that table for additional notes. The optimal age-varying dosage is not a single number but the vector plotted in Figure A3.

![](/documents/16d5bccc-33a3-4977-a27f-a71108970c06/images/image_013.jpg)
Figure A2: Deaths Averted Moving from Full to Fractional Dosing in a Slow-Growing Epidemic. Reprises results from Figure 10, reducing $\mathscr{R}_{0}$ from 2 to 1.1. See that figure for additional notes.

**Feedback**:
The concave-dose results at 0.01% daily supply appear inconsistent across Table A1 and Figure A2. The table's rounded values imply that both uniform and age-varying dosing avert approximately 18% of deaths under full dosing, whereas Figure A2 places the dashed age-varying curve near 22% and the solid uniform curve near 18%. The discrepancy is too large to be explained by rounding of the displayed table entries.

---

### 15. Unit-elastic notation breaks the concave case

**Status**: [Pending]

**Quote**:
> We analyzed candidates (a) and (b) in the proof of Proposition 1 , showing candidate (a) entails $n^{*}=N$ and $x^{*}=Q / N$, and candidate (b) entails $x^{*}=x^{e}$ and $n^{*}=Q / x^{e}$. To characterize the candidate (c) solution, substituting $\lambda^{*}=0$ into (A28) yields $B^{\prime}\left(n^{*} \phi\left(x^{*}\right)\right) n^{*} \phi^{\prime}\left(x^{*}\right)=0$, implying $\phi\left(x^{*}\right)=0$ since $B^{\prime}(v)>0$ for all $v \geq 0$ and $n^{*}>0$ in a nontrivial optimum.

**Feedback**:
The proof treats candidate (b) as $x^*=x^e$ and $n^*=Q/x^e$ without restricting $x^e$ to a positive unit-elastic point. For concave efficacy, the only unit-elastic point is $x^e=0$, so this candidate does not exist as a nontrivial finite policy and $Q/x^e$ is undefined. The regime argument therefore does not formally cover the concave case, even though the proposition’s intended conclusion for that case remains plausible.

---

### 16. Unit-elastic limit in subsection 3.1 needs qualification

**Status**: [Pending]

**Quote**:
> The key benchmark with costless vaccination is provided by the dosage $x^{e}$ at which efficacy is unit elastic. This point can be read off the graphs in Figure 1. For both functional forms, the origin provides one unit-elastic point. To see this, note that $\lim _{x \downarrow 0} \alpha_{\phi}(x)=\phi^{\prime}(0)$ by l'Hôpital's Rule, impliying $\lim _{x \downarrow 0} \eta_{\phi}(x)=1$ since $\eta_{\phi}(x)=\phi^{\prime}(x) / \alpha_{\phi}(x)$. While $\alpha_{\phi}(x)$ and thus $\eta_{\phi}(x)$ are undefined at $x=0$, having the $0 / 0$ form, it is natural to extend these functions to equal their right-hand limits at 0 : thus, $\alpha_{\phi}(0)=\phi^{\prime}(0)$ and $\eta_{\phi}(0)=1$. According to the last equation, the origin provides one unit-elastic point on the efficacy function.

**Feedback**:
The claimed limit $\lim_{x\downarrow 0}\eta_{\phi}(x)=1$ requires qualification because the assumptions allow $\phi'(0)=0$. If the first nonzero Taylor term of the real-analytic function $\phi$ is $a_mx^m$, then the elasticity approaches $m$, not necessarily 1; for example, $\phi(x)=1-e^{-x^2}$ is strictly sigmoid under the paper's definition and has limiting elasticity 2. Thus, for such specifications, setting $\eta_{\phi}(0)=1$ is a convention rather than a continuous extension, and the stated unit-elastic set need not include zero. The positive benchmark $\bar{x}^e$ and the main optimization results may remain intact, but the endpoint claim and corresponding proof should be qualified.

---

### 17. Concave case is undefined in Proposition 1 proof

**Status**: [Pending]

**Quote**:
> Equations (A36) and (A37) together imply $\phi^{\prime}\left(x^{*}\right)=\phi\left(x^{*}\right) / x^{*}$, implying $\eta_{\phi}\left(x^{*}\right)=1$. A nontrivial solution requires $x^{*}>0$, implying $x^{*}=\bar{x}^{e}$. Further, $n^{*}=Q / \bar{x}^{e}$ since (A33) holds with equality.

Second, suppose $\mu^{*}>0$. Then $n^{*}=N$ by (A34). Further, $x^{*}=Q / N$ since (A33) holds with equality.

One can see that the solution for $\mu^{*}=0$ corresponds to the solution of the relaxed problem omitting the population constraint (4) and thus must be the solution to the original problem as long as it does not violate the omitted constraint, i.e., as long as $n^{*}=Q / \bar{x}^{e} \leq N$, or equivalently $\bar{x}^{e} \geq$ $Q / N$. Otherwise the solution for $\mu^{*}>0$ obtains, with $x^{*}=Q / N$. Combining these solutions yields $x^{*}=\max \left\{\bar{x}^{e}, Q / N\right\}$. Since $n^{*}=Q / x^{*}$, we have $n^{*}=\min \left\{Q / \bar{x}^{e}, N\right\}$, as stated in the proposition. Q.E.D.

**Feedback**:
The proof and statement of Proposition 1 are formally undefined in the concave-efficacy case because $\bar{x}^{e}=0$, making $Q/\bar{x}^{e}$ a division by zero. In that case the $\mu^{*}=0$ branch has no positive solution; the valid conclusion instead comes from the $\mu^{*}>0$ branch, which gives $n^{*}=N$ and $x^{*}=Q/N$.

---

### 18. Comparative-static conditions are overstated

**Status**: [Pending]

**Quote**:
> These comparative statics are inherited by the optimal dosage $x^{*}$ since $x^{*}=\bar{x}^{s}(Q)$ in this region. It is possible that $x^{*}$ increases as $Q$ falls. According to Propositions 3-5, the necessary and sufficient conditions for this outcome are that $\phi$ is stricly sigmoid, $s$ is convex, and $k$ is sufficiently low.

Extreme examples can be constructed in which the curve turns so sharply upward as $Q$ approaches 0 that $\bar{x}^{s}(Q)$ is higher in that limit than the unconstrained dose $\bar{x}^{u}$. In such extreme cases, $x^{*}$ is highest when supply constraints are the tightest.

**Feedback**:
The claimed necessary-and-sufficient characterization is too broad: weak convexity of $s$ and a low positive $k$ do not suffice, because linear side effects are convex but Proposition 4 rules out the counterintuitive slope. The exact condition is $k<\bar{x}^{e}s'(\bar{x}^{e})-s(\bar{x}^{e})$; a positive admissible threshold requires curvature beyond linearity on the relevant interval.

---

### 19. Abstract overstates the concave-case result

**Status**: [Pending]

**Quote**:
> We study optimal fractional dosing in a tractable model capturing the essence of more complex epidemiological studies. Under a concave dose-response function, fractional dosing is always optimal if supplies are insufficient to deliver full doses to the entire population, and optimal dose strength is weakly increasing in vaccine supply. The same is often true under an s-shaped dose-response function, although exceptions can arise where a further tightening of extremely scarce supplies leads to more concentrated doses.

**Feedback**:
The Abstract's concave-case claim is too broad for the costly-vaccination model. If $\rho^0(N)<1$ and $\bar n^0<N$, a supply level satisfying $\bar n^0\bar x^0\leq Q<N\bar x^0$ cannot provide the normal-times dose to everyone but can still implement the unconstrained optimum $(\bar n^0,\bar x^0)$. The dose is then not stretched under the paper's normal-times definition. The unconditional claim holds in the costless case, while the costly case requires an additional condition making universal coverage desirable.

---

### 20. Introduction lacks a finite full-dose benchmark

**Status**: [Pending]

**Quote**:
> With costless vaccination and a concave dose-response function, the whole population should be vaccinated with full doses if possible; but if supplies of the active ingredient are too scarce for that, fractional doses should be spread to the whole population. This prescription leads to a straightforward formula for optimal dosage in the region of scarce supplies: dose size should vary linearly with the supply of the active ingredient. This is exactly the relationship that Riley, Wu, and Leung (2007) find in every case (see their Figure 2)-a result we could have predicted without resorting to simulations, knowing only that their calibrated dose-response functions are concave.

**Feedback**:
The phrase “full doses if possible” is not supported by the costless, everywhere-increasing baseline being previewed. With $g(x)=0$ and concave $\phi$, Proposition 1 implies $n^*=N$ and $x^*=Q/N$ for every finite positive $Q$; there is no finite unconstrained or normal-times dose at which the planner stops increasing dose strength. A finite full-dose benchmark appears only with peaked efficacy, through $x^p$, or through an external approved-dose normalization, so the introduction conflates the baseline result with the later extension and calibration.

---

### 21. Empirical examples do not establish equal efficacy

**Status**: [Pending]

**Quote**:
> Our calibration may considerably understate the potential for gains from fractional dosing in many real-world cases. The introduction mentioned that fifth doses were used in the 2018 yellow fever and 2022 mpox outbreaks. In both cases randomised trials suggested immunological noninferiority (Juan-Giner et al., 2021; Centers for Disease Control and Prevention, 2026). In the context of our model this suggests that full doses for these vaccines must be very far out on the long plateau of dose-response functions. This is in contrast to our calibration example which assumed a large drop-off in efficacy at low doses.

That the full dose was five times more concentrated than needed for the same efficacy is remarkable.

**Feedback**:
The inference from immunological noninferiority to equal protective efficacy is stronger than the evidence described. Immunological noninferiority does not by itself establish equality in the model’s clinical-protection parameter $\phi$, and the document earlier reports mpox effectiveness point estimates of 75% and 86%. The claims that one-fifth doses provide the “same efficacy” and that full doses must lie far out on a long efficacy plateau therefore require an explicit link between the immune endpoint and clinical protection.

---

### 22. Lemma 4 uses unassumed strict cost convexity

**Status**: [Pending]

**Quote**:
> Similarly, we can write

$$
\eta_{g}^{\prime}(x)=\frac{x g^{\prime \prime}(x)}{g(x)}+H\left(x, \eta_{g}(x)\right) .
$$

Given $g^{\prime \prime}(x)>0$ for all $x>0$,

$$
\eta_{g}^{\prime}(x)>H\left(x, \eta_{g}(x)\right),
$$

establishing $\eta_{g}(x)$ as an over-function relative to $\eta(x)$ on $\left[\underline{x}^{0}, \infty\right)$ according Definition 1.2.1 from Lakshmikantham and Leela (1969). By Theorem 1.3.2 of Lakshmikantham and Leela (1969), since $\eta_{\phi}(x)$ is an under-function and $\eta_{g}(x)$ an over-function relative to the same function on $\left[\underline{x}^{0}, \infty\right)$ and $\eta_{\phi}\left(\underline{x}^{0}\right)=\eta_{g}\left(\underline{x}^{0}\right), \eta_{\phi}(x)<\eta_{g}(x)$ for all $x>\underline{x}^{0}$. Thus, no $x>\underline{x}^{0}$ can satisfy (11), a necessary condition for a solution $x^{0}$, implying $\bar{x}^{0} \nsucceq \underline{x}^{0}$, implying $\underline{x}^{0}=\bar{x}^{0}$. Q.E.D.

**Feedback**:
The proof of Lemma 4 invokes $g''(x)>0$, but the maintained assumptions imply only $g''(x)=s''(x)\geq 0$ and expressly allow linear side effects. The displayed strict differential inequality is therefore not established; the uniqueness argument should be justified under weak convexity. The lemma itself may still follow because efficacy is strictly concave on the relevant interval.

---

### 23. Section 6.3 misstates the denominator of its gain metric

**Status**: [Pending]

**Quote**:
> Figure 10 helps visualize the improvement of fractional over full doses, graphing the metric in equation (35). The percent of full-dose deaths averted is hump-shaped. When supplies are very low, fractional dosing cannot generate a big improvement because few deaths can be averted with any dosing policy. When supplies are very high, almost all deaths can be averted with full doses, so little room for improvement is left for fractional dosing. The percent improvement is greatest for moderate supplies. In particular, the curves peak at about $0.6 \%$ of the population supplied per day. At this supply level, fractional dosing increases averted deaths by 30-35\% depending on the shape of the dose-response function.

**Feedback**:
Equation (35) normalizes the additional deaths prevented by the number of deaths remaining under full dosing. Thus, the reported 30–35% is the share of residual full-dose deaths eliminated by fractional dosing, not the percentage increase in the number of deaths averted, whose denominator would be $AD(0)-AD(x^p)$.

---

### 24. Abstract’s 40% gain uses a different denominator

**Status**: [Pending]

**Quote**:
> The same is often true under an s-shaped dose-response function, although exceptions can arise where a further tightening of extremely scarce supplies leads to more concentrated doses. The analysis then shifts to deriving quantitative results from a dynamic epidemiological model, allowing mortality and disease transmission to vary by age, calibrated to Covid-19 parameters. The gains from fractional dosing can be substantial, increasing the number of deaths averted by full doses by as much as 40\%.

**Feedback**:
The Abstract's wording mischaracterizes the 40\% statistic. Equation (35), $(AD(x^p)-AD(X))/AD(x^p)$, is the fraction of deaths remaining under full dosing that fractional dosing averts. A percentage increase in the number of deaths already averted by full doses would instead divide by $AD(0)-AD(x^p)$. These denominators are not interchangeable.

---

### 25. Proposition 5 conflicts with the conclusion on fixed cost

**Status**: [Pending]

**Quote**:
> When $s(x)$ is strictly convex, the sign of $d \bar{x}^{s}(Q) / d Q$ can be tied to the level of the fixed vaccination cost, $k$.

Proposition 5. Suppose the side-effect function is strictly convex, i.e., $s^{\prime \prime}(x)>0$ for all $x>0$. Then

$$
\operatorname{sgn}\left(\frac{d \bar{x}^{S}(Q)}{d Q}\right)=\operatorname{sgn}(k-\hat{k}),
$$

where $\hat{k} \equiv \bar{x}^{e} s^{\prime}\left(\bar{x}^{e}\right)-s\left(\bar{x}^{e}\right)$. If $\phi$ is concave, then $\hat{k}=0$; if $\phi$ is strictly sigmoid, then $\hat{k}>0$.
The proof is again almost immediate from Proposition 2. Using the expression for $\hat{k}$ from the statement of the proposition, for any $s(x)$, we can write $1-\eta_{g}\left(\bar{x}^{e}\right)=(k-\hat{k}) / g\left(\bar{x}^{e}\right)$. Hence, by Proposition 2, the sign of $k-\hat{k}$ determines the sign of $d \bar{x}^{s}(Q) / d Q$.

**Feedback**:
The Conclusion reverses Proposition 5’s fixed-cost condition. The counterintuitive case in which lower supply leads to a stronger dose requires $d\bar{x}^s/dQ<0$, hence $k<\hat{k}$, whereas the Conclusion says that it occurs when fixed administration costs are sufficiently high.

---

### 26. Lemma 3’s zero-objective claim needs correction

**Status**: [Pending]

**Quote**:
> Since the planner's objective (2) equals zero when evaluated at either $n=0$ or $x=0$, for the planner's solution $\left(n^{*}, x^{*}\right)$ to be nontrivial, it must generate a positive value for (2). Thus,

$$
\begin{aligned}
0 & <B\left(n^{*} \phi\left(x^{*}\right)\right)-n^{*} g\left(x^{*}\right) \\

**Feedback**:
The proof of Lemma 3 incorrectly states that the objective is zero whenever $x=0$. Since $g(0)=k>0$ and $\phi(0)=0$, its value is $-nk$, which is zero only when $n=0$. Moreover, the feasible policy $n=0$ establishes only weakly nonnegative optimal surplus. The displayed strict inequality follows by additionally using strict concavity of $B$: a nontrivial zero-surplus optimum would be strictly dominated by proportionally reducing $n$. The lemma remains valid, but this missing argument is needed in its proof.

---

### 27. The full-dose benchmark is absent in Section 3.2

**Status**: [Pending]

**Quote**:
> Given vaccination is costless and benefits and efficacy do not hit peaks, there is no largest optimal dose. For very high levels of capacity $Q$, the optimal dose vaccinates the whole population with the largest possible dose allowed by available capacity: $x^{*}=Q / N$. No matter how high $Q$ is, the optimal dose can still be considered "fractional" relative to the optimal dose for yet higher capacity. Fractional dosing is the rule, not the exception.

**Feedback**:
The claim that every finite $Q/N$ can be considered a fractional dose uses a different benchmark from the paper’s definition of stretching relative to a normal-times optimum. In this costless, everywhere-increasing-efficacy model, no finite unconstrained optimal dose exists. Thus the optimization establishes how dosage varies with supply, but it does not by itself establish fractionation relative to a fixed full-dose benchmark.

---

### 28. Lemma 4 uses an ambiguous unit-elastic point

**Status**: [Pending]

**Quote**:
> The preceding sketch of the analysis glossed over some technical details. It remains to be verified that $X^{0}$ is nonempty and finite so that its largest element $\bar{x}^{0}$ is well defined. The following lemma fills in those technical details. It also provides a useful result, positioning $\bar{x}^{0}$ relative to the unit-elastic benchmark $x^{e}$ : if $\bar{x}^{0} \geq x^{e}$, then $X^{0}$ is a singleton. This result follows since if any solution $x^{0}$ lies above $x^{e}$, it lies above the point of inflection for $\phi$, in the range where $\phi$ is a well-behaved concave function, generating a unique optimum.

Lemma 4. There exists a unique $\bar{x}^{0}>0$ satisfying $\bar{x}^{0}=\max \left(X^{0}\right)$. If $\bar{x}^{0} \geq x^{e}$, then $X^{0}=\left\{\bar{x}^{0}\right\}$.

**Feedback**:
Lemma 4’s condition must refer to the maximal unit-elastic benchmark $\bar{x}^{e}$ rather than an arbitrary $x^{e}\in X^{e}$. For strictly sigmoid efficacy, the arbitrary choice $x^{e}=0$ would make $\bar{x}^{0}\geq x^{e}$ automatic without placing $\bar{x}^{0}$ above the inflection point; both the stated explanation and the appendix argument instead rely on $\bar{x}^{e}>x^{i}$.

---

### 29. Section 6.3 treats efficacy as a mortality ceiling

**Status**: [Pending]

**Quote**:
> With ten times more vaccine supply than the benchmark (1\% of the population vaccinated each day), full doses avert most deaths (88\%). Capacity of this magnitude speeds doses to the population so quickly that there is little gain from speeding the process further with fractional doses. Uniform fractional doses are 70\% of the strength of full doses, averting 91\% of deaths, only three percentage points more than full doses. When vaccine supply is increased another ten fold-to 10\% of the population vaccinated each day-at that point supply is all but unconstrained, essentially leaving no room for fractional doses to generate improvements. Full doses already avert 95\% of deaths, the maximum possible given the vaccine is calibrated to be 95\% effective.

**Feedback**:
Individual efficacy of 95% is not an upper bound on aggregate deaths averted in the SEIRDV model. Successful vaccination also suppresses transmission and can indirectly protect people for whom the vaccine fails, so aggregate mortality reduction may exceed $\phi(1)=0.95$. The table’s rounded 95% may be a valid simulation result, but it is not a maximum implied solely by the efficacy calibration.

---

### 30. Reversed inequality does not imply population feasibility

**Status**: [Pending]

**Quote**:
> Optimum When $\rho^{0}(N) \leq 1$. Next, suppose $\rho^{0}(N) \leq 1$. Repeating (A86)-(A89) reversing the inequality yields

$$
n^{0} \leq N .
$$

The unconstrained solution $\left(n^{0}, x^{0}\right)$ thus satisfies the population constraint (4). It is the optimum if it also satisfies supply constraint (3), requiring $n^{0} x^{0} \leq Q$.

**Feedback**:
Reversing (A86)–(A89) establishes only $N\phi(\bar{x}^0)\geq n^0\phi(x^0)$, which does not imply $n^0\leq N$ for an arbitrary $x^0\in X^0$. The desired conclusion is valid for the particular pair $(\bar n^0,\bar x^0)$, where the same efficacy factor appears on both sides, but not for every unconstrained solution as stated.

---

### 31. Footnote 11 conflates basic and effective reproduction

**Status**: [Pending]

**Quote**:
> ${ }^{11}$ In reality, $\mathscr{R}_{0}$ did not have a single, well-defined value for Covid-19 but varied widely across regions and time in response to social distancing, lockdowns, and continual emergence of new variants of the virus.

**Feedback**:
Footnote 11 uses $\mathscr{R}_0$ for variation attributed to distancing and lockdowns, while the simulations treat it as a fixed calibration target. Under the usual distinction, policy-induced changes in realized contacts affect a control or effective reproduction number; variants or alternative baseline contact environments may instead change the context-specific basic reproduction number. The $2$ and $1.1$ exercises are coherent as alternative fixed-parameter fast- and slow-growing epidemics, but not as an explicit simulation of time-varying distancing.

---

### 32. Universal-dose notation shifts in Section 4.5

**Status**: [Pending]

**Quote**:
> The dense notation in the proposition obscures the rather straightforward structure of the optimal policy, which can be visualized with the help of Figure 4. Start with the upper panel, showing the optimal policy when $\rho^{0}(N)>1$. This inequality ensures that the planner prefers to vaccinate the whole population if supplies allow. For sufficiently high supply $Q$ in this panel, there is no stretching or rationing. The entire population is vaccinated with the universal-vaccination benchmark dosage, $\bar{x}^{u}$.

As $Q$ falls below $N \bar{x}^{u}$, the capacity constraint begins to bind. The optimal dose is initially stretched so all individuals can still be vaccinated. For sufficiently tight capacity, below threshold

**Feedback**:
The prose after Proposition 6 switches from the defined $\underline{x}^{u}$ to the undefined $\bar{x}^{u}$. This conflicts with the proposition and proof, where the smallest universal-coverage maximizer determines feasibility; if $X^{u}$ has multiple elements, a threshold based on its largest element would classify some supplies incorrectly.

---

### 33. Change of variables is undefined at zero dose

**Status**: [Pending]

**Quote**:
> Considerable insight can be gained by examing the problem that is equivalent to (8) but makes the change of variables $v=n \phi(x)$ and solves for the optimal number of successful immunizations
$v$ rather than the optimal number of vaccinations $n$. Equation (8) becomes

$$
\max _{v, x \geq 0}\left[B(v)-v \cdot \frac{g(x)}{\phi(x)}\right] .
$$

It is immediate that the unconstrained-optimal dose $x^{0}$ maximizes the ratio $\phi(x) / g(x)$.

**Feedback**:
The transformed problem is not literally defined on its displayed domain. At $x=0$, $\phi(0)=0$ and $g(0)=k>0$, so $g(x)/\phi(x)$ and the recovery $n=v/\phi(x)$ are undefined, while $(v,0)$ with $v>0$ is unattainable from the original problem. The claimed equivalence therefore requires restricting attention to $x>0$ or an appropriate extended-value convention; the intended positive-dose characterization is otherwise unaffected.

---

### 34. Figure 9 leaves the dosing policy unidentified

**Status**: [Pending]

**Quote**:
> Calibration Methods. While some simple compartmental models admit closed-form solutions (see, e.g., Goodkin-Gold et al., 2024), complex models like the one here-with more compartments and heterogeneous cohorts-have no known analytical solutions. Therefore, we rely on numerical methods to simulate the time path of the model's compartments and evaluate the objective function behind the dose-optimization problem. ${ }^{15}$ We run all simulations for 365 days.

[^8]![](/documents/16d5bccc-33a3-4977-a27f-a71108970c06/images/image_009.jpg)
Figure 9: Evolution of Compartments in Calibrated Model. Simulates outcome from SEIRDV model for various levels of vaccine capacity. Simulation allows proportions in compartments to vary across age cohorts; graphs here aggregate age cohorts, showing proportions of total population.

**Feedback**:
Figure 9 appears to use dose-dependent accelerated rollout, but its caption does not identify the dosing policy or dose-response shape. In particular, the 0.1% full-dose-equivalent trajectory seems to approach roughly 63% vaccinated within a year, above the 36.5% achievable with full doses at that supply. This is plausible under fractional dosing, but without the governing dose the figure cannot be checked or interpreted as a full-dose baseline.

---

### 35. Missing chain-rule factor in Lemma 7 proof

**Status**: [Pending]

**Quote**:
> We have

$$
\begin{aligned}
B\left(N \phi\left(x^{0}\right)\right)-N g\left(x^{0}\right) & =\int_{0}^{N}\left[B^{\prime}\left(n \phi\left(x^{0}\right)\right)-g\left(x^{0}\right)\right] d n \\
& >\int_{0}^{N}\left[B^{\prime}\left(N \phi\left(x^{0}\right)\right)-g\left(x^{0}\right)\right] d n
\end{aligned}
$$

The first line follows from the Fundamental Theorem of Calculus. The second line follows from the concavity of $B$, which implies $B^{\prime}\left(n \phi\left(x^{0}\right)\right)>B^{\prime}\left(N \phi\left(x^{0}\right)\right)$ for all $n \in(0, N)$. The right-hand side of (A65) is positive because its integrand is positive by (A63). Thus, (A57) is positive for some interior $x$, namely $x^{0}$.

**Feedback**:
In the proof of Lemma 7, the Fundamental Theorem of Calculus identity omits the chain-rule factor $\phi(x^{0})$: the correct integrand is $B'(n\phi(x^{0}))\phi(x^{0})-g(x^{0})$. The displayed equality is therefore false as written, although restoring this factor makes the intended positivity argument valid under the lemma’s assumptions.

---

### 36. Missing efficacy factor in Lemma 8 surplus identity

**Status**: [Pending]

**Quote**:
> Consider a policy of distributing doses of size $\bar{x}^{0}$ to $Q / \bar{x}^{0}$ individuals, for $Q \in(0, \tilde{Q}]$. The social surplus from this policy equals

$$
\begin{aligned}
B\left(Q \alpha_{\phi}\left(\bar{x}^{0}\right)\right)-Q \alpha_{g}\left(\bar{x}^{0}\right) & =\int_{0}^{Q / \bar{x}^{0}}\left[B^{\prime}\left(n \phi\left(\bar{x}^{0}\right)\right)-g\left(\bar{x}^{0}\right)\right] d n \\
& >\int_{0}^{Q / \bar{x}^{0}}\left[B^{\prime}\left(Q \alpha_{\phi}\left(\bar{x}^{0}\right)\right)-g\left(\bar{x}^{0}\right)\right] d n
\end{aligned}
$$

Equation (A75) follows from the Fundamental Theorem of Calculus. Condition (A76) follows since $B^{\prime \prime}<0$, implying $B^{\prime}\left(n \phi\left(\bar{x}^{0}\right)\right)>B^{\prime}\left(\left(Q / \bar{x}^{0}\right) \phi\left(\bar{x}^{0}\right)\right)$ for all $n \in\left(0, Q / \bar{x}^{0}\right)$. The integral in (A76) is positive since its integrand is by (A73). The proposed policy thus generates positive social surplus.

**Feedback**:
In the proof of Lemma 8, the surplus identity omits the chain-rule factor $\phi(\bar{x}^{0})$: the correct integrand is $B'(n\phi(\bar{x}^{0}))\phi(\bar{x}^{0})-g(\bar{x}^{0})$. Thus, (A75)–(A76) are incorrect as written, although inserting the factor yields the intended positive-surplus conclusion directly from (A73).

---

### 37. Low-supply KKT candidates are interchanged

**Status**: [Pending]

**Quote**:
> Suppose $Q \leq N x^{e}$. Then we can show candidate (c) is infeasible, requiring an infeasible capacity: $n^{*} x^{*}=N x^{p}>N x^{e} \geq Q$ since $x^{p}>x^{e}$ as shown in the previous paragraph. One of the two remaining candidates, (a) or (b), must provide the optimum. Candidate (a) omits a constraint
relative to case (b) so must provide a weakly better solution unless it violates the omitted population constraint. The number of vaccinations specified by candidate (a) is $n^{*}=Q / x^{e} \leq N$, where the inequality follows from the maintained condition $Q \leq N x^{e}$. Hence candidate (a) respects the omitted population constraint and provides the optimum.

**Feedback**:
The low-supply paragraph interchanges candidates (a) and (b). Candidate (b), not candidate (a), has $x^*=x^e$ and $n^*=Q/x^e$ and solves the problem with the population constraint omitted. Thus candidate (b) is the low-supply optimum whenever that positive unit-elastic candidate exists.

---

### 38. Derivative dropped in Proposition 7 candidate (c)

**Status**: [Pending]

**Quote**:
> To characterize the candidate (c) solution, substituting $\lambda^{*}=0$ into (A28) yields $B^{\prime}\left(n^{*} \phi\left(x^{*}\right)\right) n^{*} \phi^{\prime}\left(x^{*}\right)=0$, implying $\phi\left(x^{*}\right)=0$ since $B^{\prime}(v)>0$ for all $v \geq 0$ and $n^{*}>0$ in a nontrivial optimum. But $\phi\left(x^{*}\right)=0$ implies $x^{*}=x^{p}$. Substituting $\mu^{*}>0$ into (A34) implies $n^{*}=N$.

**Feedback**:
Candidate (c) satisfies $\phi'(x^*)=0$, not $\phi(x^*)=0$. It is this derivative condition that identifies the efficacy peak $x^p$; efficacy at the peak is not zero.

---

### 39. Concave case makes Proposition 7 undefined

**Status**: [Pending]

**Quote**:
> Proposition 7. Suppose vaccination is costless to the planner, i.e., $g(x)=0$, and efficacy has a peak at $x^{p}$. The optimal policy vaccinates $n^{*}=\min \left\{Q / \bar{x}^{e}, N\right\}$ individuals with dose $x^{*}=$

**Feedback**:
Proposition 7’s formula for $n^{*}$ is undefined in the concave case because $\bar{x}^{e}=0$ and $Q>0$. The intended outcome $n^{*}=N$ follows only under an unstated extended-real or limiting convention, so the formal statement does not cover one of its stated efficacy cases.

---

### 40. Age-cohort count in the calibration preview

**Status**: [Pending]

**Quote**:
> To assess the quantitative importance of the results from the reduced-form model, the second part of the paper turns to constructing and simulating a full-blown epidemiological model. We adapt the epidemiological model from our own previous work Więcek et al. (2022), which allows for heterogeneity in mortality risk and a flexible contact matrix across seven age cohorts and is calibrated to the Covid-19 pandemic. The dynamic vaccination process distributes doses to cohorts prioritized by risk in a flow constrained by available capacity.

**Feedback**:
The calibration preview says the epidemiological model has seven age cohorts, whereas Section 6.2 specifies eight: one child cohort and seven adult cohorts. The seven-dimensional dosing vector counts only the vaccine-eligible adult cohorts; the SEIRDV system and contact matrix also include the child cohort.

---

### 41. Section 3.2 invokes the wrong unit-elastic point

**Status**: [Pending]

**Quote**:
> Since $B$ is increasing in its argument and $Q$ is a constant, we see that the $x^{*}$ should maximize per-unit efficacy $\alpha_{\phi}(x)$ and thus equal $x^{e}$ by Lemma 2. This is the optimal dose unless unless it would leave some capacity unused even if all $N$ individuals were vaccinated with it. In that case, the optimum simply vaccinates the entire population $\left(n^{*}=N\right)$ with the largest possible dose subject to available capacity $\left(x^{*}=Q / N\right)$. The following proposition synthesizes this analysis.

**Feedback**:
The deduction should invoke $\bar{x}^{e}$ rather than an arbitrary $x^{e}$. For strictly sigmoid efficacy, $x^{e}$ may denote the zero element of $X^{e}$, whereas Lemma 2 identifies the positive point $\bar{x}^{e}$ as the maximizer of per-unit efficacy. Proposition 1 uses the correct benchmark.

---

### 42. Section 2 margin is undefined at zero price

**Status**: [Pending]

**Quote**:
> The planner's expenditures include spending on the vaccine's active ingredient (antigen), for which the planner pays an exogenous unit price $p \geq 0 .{ }^{6}$ This price may equal unit cost $c$ or may reflect a margin $m \equiv(p-c) / p$ above $c$.

The planner also expends $k \geq 0$ per dose to administer the vaccine, independent of the dose's strength. This includes the cost of filling and finishing the vaccine vial, transporting the vials to dispensaries, and labor and facilities involved in administering a dose to a consumer. If the social planner internalizes the consumer's cost of traveling to the dispensary and the pain of being jabbed, those costs could be included in $k$ as well.

**Feedback**:
The normalized margin $m=(p-c)/p$ is undefined at the permitted boundary $p=0$. This is a localized notational-domain issue: $m$ is not used in the optimization, so it does not affect the costless-vaccination results, but the definition is valid only when $p>0$.

---
