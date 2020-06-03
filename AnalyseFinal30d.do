clear all

cd "/Users/guillaume/MyProjects/StataProjects/Rem_2020/Project/DictatorShip/AnalyseFinal/AnalyseTotal"

ssc install estout, replace
ssc install outreg2, replace


import excel "dataCleaner.xlsx",sheet("30d") firstrow clear

drop in 64/1004
// Logarithme du nombre de morts //

gen lnDeath = ln(DeathsAfter1000confirmed30d)

gen MortsPerHabitant = DeathsAfter1000confirmed30d/POPulationenmilliers
egen meanDeathByHab = mean(MortsPerHabitant)
////////////////////////////////////////////
// Génération des variables de contrôles //
//////////////////////////////////////////

global controls "GDPpercapital2008 numberTest Migration HealthBudgetgdp AgeMoyenPopulation"

////////////////////////////////////////
//Calcul des seuils d'individualisme //
//////////////////////////////////////
gen Ind60 = 0
replace Ind60 = 1 if IndexCollecidv >= 60

gen Ind70 = 0
replace Ind70 = 1 if IndexCollecidv >= 70

gen Ind80 = 0
replace Ind80 = 1 if IndexCollecidv >= 80

gen Demo60 = 0
replace Demo60 = 1 if DemocracyindexEIU >=60

gen Demo70 = 0
replace Demo70 = 1 if DemocracyindexEIU >=70

gen Demo80 = 0
replace Demo80 = 1 if DemocracyindexEIU >=80
////////////////////////////////
// Statistiques descriptives //
//////////////////////////////

describe

// Tester la collinéarité
estpost collin DemocracyindexEIU IndexCollecidv POPulationenmilliers $controls
esttab using test.doc
// Etude Moyenne, Ecart-type, min, max //
estpost tabstat DeathsAfter1000confirmed30d DemocracyindexEIU IndexCollecidv, stat(mean, sd, min, max) col(stat) listwise
est store c2
esttab using "30d/tabstat30d.doc", replace cells("mean(fmt(a3)) sd min max") nostar unstack

//A voir si c'est utile
tabstat DeathsAfter1000confirmed30d DemocracyindexEIU IndexCollecidv,by(Ind60) stat(mean, sd, min, max) col(stat) long
tabstat DeathsAfter1000confirmed30d DemocracyindexEIU IndexCollecidv,by(Ind70) stat(mean, sd, min, max) col(stat) long
tabstat DeathsAfter1000confirmed30d DemocracyindexEIU IndexCollecidv,by(Ind80) stat(mean, sd, min, max) col(stat) long
tabstat MortsPerHabitant
// Etude de la corrélation //
estpost corr DeathsAfter1000confirmed30d DemocracyindexEIU IndexCollecidv numberTest PolityII
est store c1
esttab * using "30d/Correlation.doc",replace unstack not noobs compress
tabstat DeathsAfter1000confirmed30d DemocracyindexEIU IndexCollecidv, stat(mean, sd, min, max) col(stat) long

graph matrix DeathsAfter1000confirmed30d DemocracyindexEIU IndexCollecidv,  half 
// matrice de correlation avec des graphes
graph matrix MortsPerHabitant DemocracyindexEIU IndexCollecidv $controls,  half
graph save "30d/matrixCorrelation.png", replace

graph matrix DemocracyindexEIU Ind60 Ind70 Ind80,  half
graph save "30d/matrixCorrelationInd.png", replace

/////////////////////////////////////////////////////
// Etudier les distribution pour la rendre normal //
///////////////////////////////////////////////////

gladder DeathsAfter1000confirmed30d
gladder PolityII
gladder DemocracyindexEIU

/////////////////////////////////////////////////////////////////
// Prediction du nombre de mort avec l'index d'individualisme //
///////////////////////////////////////////////////////////////

graph twoway (fpfit DeathsAfter1000confirmed30d IndexCollecidv, ///
legend(label(1 "Nombre de morts prédits") label(2 "nombre de morts (Pays)") ) ytitle("{bf:Nombre de morts}" " ") yline(717.283,lcolor(red) lpattern(dash)) xline(60 70 80,lcolor(green) lpattern(dash)) ///
graphregion(fcolor(gs15))) (scatter DeathsAfter1000confirmed30d IndexCollecidv,xtitle("{bf:Indice d'individualisme}") ///
text(1000 10 "Moyenne Mort", color(red) box) text(5000 60 "Seuil: 60", place(w) color(green) box) text(5500 70 "Seuil: 70", place(w) color(green) box) text(6000 80 "Seuil: 80", place(w) color(green) box) title("Prediction du nombre de morts selon l'indice d'invidualisme",size(medium) box bexpand) mlabel(Country) ///
note("{bf:Source:} JHU & Geert Hofstede"))


// Graphe pour la prédiction d'un effet linéaire de l'indice d'individualisme
graph twoway (lfit MortsPerHabitant IndexCollecidv, ///
legend(size(*0.8) label(1 "Nombre de morts par habitants prédits") label(2 "Morts par habitants (Pays)")) ytitle("{bf:Nombre de morts  / Population (en milliers)}" " ", size(small)) yline(0.0537214,lcolor(red)) xline(60 70 80,lcolor(green) lpattern(dash)) ///
graphregion(fcolor(gs15))) (scatter MortsPerHabitant IndexCollecidv,xtitle("{bf:Indice d'individualisme}", size(small)) ///
ylabel(0(.05)0.4) text(0.25 60 "Seuil: 60", color(green) box) text(0.07 22 "Moyenne : 0.054", place(w) color(red)) text(0.28 70 "Seuil: 70", place(w) color(green) box) text(0.32 80 "Seuil: 80", place(w) color(green) box) title("Prediction du nombre de morts par habitants selon l'indice d'invidualisme" "({it:30 jours après le 1000 cas confirmés})",size(medsmall) box bexpand) mlabel(Country) ///
note("{bf:Source:} JHU & Geert Hofstede"))

graph export "30d/PredictionMortsPerHabitants.png", replace

graph twoway (lfit MortsPerHabitant DemocracyindexEIU, ///
legend(size(*0.8) label(1 "Nombre de morts par habitants prédits") label(2 "Morts par habitants (Pays)") ) ytitle("{bf:Nombre de morts  / Population (en milliers)}" " ", size(small)) yline(0.0537214,lcolor(red)) ///
graphregion(fcolor(gs15))) (scatter MortsPerHabitant DemocracyindexEIU,xtitle("{bf:Democracy Index}") ///
ylabel(0(.05)0.4) text(0.07 37 "Moyenne : 0.054", place(w) color(red)) title("Prediction du nombre de morts selon le Democracy Index" "({it:30 jours après le 1000 cas confirmés})",size(medsmall) box bexpand) mlabel(Country) ///
note("{bf:Source:} JHU & Geert Hofstede"))

graph export "30d/PredictionMortsPerHabitantsDemo.png", replace
//correlate lnDeath DemocracyindexEIU IndexCollecidv numberTest PolityII
//graph matrix DeathsAfter1000confirmed20d PolityII IndexCollecidv 

twoway scatter DeathsAfter1000confirmed30d IndexCollecidv || qfit DeathsAfter1000confirmed30d IndexCollecidv if IndexCollecidv >= 55
histogram DemocracyindexEIU , frequency normal name(DemoIndex)
//twoway qfitci DeathsAfter1000confirmed20d IndexCollecidv || scatter DeathsAfter1000confirmed20d IndexCollecidv


/////////////////
// Clustering //
///////////////

cluster k DeathsAfter1000confirmed30d PolityII IndexCollecidv numberTest, k(3) name(g3) s(krandom(385617))
graph matrix DeathsAfter1000confirmed30d PolityII IndexCollecidv if g3!=. , m(i) mlabel(g3) mlabpos(0) half

//////////////////////////////////////////////
// Graphe correlation avec le nom des pays //
////////////////////////////////////////////

graph matrix DeathsAfter1000confirmed30d PolityII IndexCollecidv if g3!=., m(i) mlabel(Country) mlabpos(0) half


graph export death20dCorr.pdf, replace

/////////////////
// Regression //
///////////////

// Génération des effets d'interactions //

gen effetInteractionInd60DemoIndex = Ind60*DemocracyindexEIU
gen effetInteractionInd70DemoIndex = Ind70*DemocracyindexEIU
gen effetInteractionInd80DemoIndex = Ind80*DemocracyindexEIU

// régression //
eststo: quietly reg DeathsAfter1000confirmed30d DemocracyindexEIU , robust
eststo: quietly reg DeathsAfter1000confirmed30d DemocracyindexEIU $controls, robust

esttab using "30d/regDemoIndex.doc", replace p(4) r2(4) ar2(4)

eststo clear

eststo: quietly reg MortsPerHabitant IndexCollecidv $controls, robust
estadd local Controls "Oui"
eststo: quietly reg MortsPerHabitant DemocracyindexEIU $controls, robust
estadd local Controls "Oui"
esttab using "30d/regVarContinue.tex", replace p(4) scalars("Controls Contrôles") r2(4) ar2(4) drop(*$controls)

eststo clear

eststo: quietly reg lnDeath DemocracyindexEIU , robust

eststo: quietly reg lnDeath DemocracyindexEIU $controls, robust

esttab using "30d/reglnDemoIndex.doc", replace p(4) r2(4) ar2(4)

eststo clear

eststo: quietly reg MortsPerHabitant DemocracyindexEIU , robust
estadd local Controls "Non"
eststo: quietly reg MortsPerHabitant DemocracyindexEIU $controls, robust
estadd local Controls "Oui"
esttab using "30d/regDemoIndexParHabitant.doc", replace p(4) scalars("Controls Contrôles") r2(4) ar2(4) drop(*$controls)

eststo clear

eststo: quietly reg MortsPerHabitant IndexCollecidv , robust
estadd local Controls "Non"
eststo: quietly reg MortsPerHabitant IndexCollecidv $controls, robust
estadd local Controls "Oui"
esttab using "30d/regIndivIndexParHabitant.doc", replace p(4) scalars("Controls Contrôles") r2(4) ar2(4) drop(*$controls)

eststo clear

//IndexInd > 60 // -> pas d'effet
eststo: quietly reg DeathsAfter1000confirmed30d Ind60, robust
estadd local Controls "Non"
eststo: quietly reg DeathsAfter1000confirmed30d Ind60 $controls, robust
estadd local Controls "Oui"
esttab using "30d/regIndiv6030j.doc", replace p(4) scalars("Controls Contrôles") r2(4) ar2(4) drop(*$controls) mlabel("Morts20j" "Morts20j")

eststo clear

reg DeathsAfter1000confirmed30d Ind60 DemocracyindexEIU $controls, robust

eststo: quietly reg lnDeath Ind60, robust
estadd local Controls "Non"
eststo: quietly reg lnDeath Ind60 $controls, robust
estadd local Controls "Oui"
esttab using "30d/regLnIndiv6030j.doc", replace p(4) scalars("Controls Contrôles") r2(4) ar2(4) drop(*$controls) mlabel("log(Morts20j)" "log(Morts20j)")

eststo clear

// Bonne régression  Ind 60//
eststo: quietly reg MortsPerHabitant Ind60, robust
estadd local Controls "Non"
eststo: quietly reg MortsPerHabitant Ind60 $controls, robust
estadd local Controls "Oui"
esttab using "30d/regMortPerHabIndiv7030j.doc", replace p(4) scalars("Controls Contrôles") r2(4) ar2(4) drop(*$controls) 

eststo clear

reg lnDeath Ind60 DemocracyindexEIU $controls, robust
reg lnDeath Ind60##c.DemocracyindexEIU $controls, robust

// IndexInd > 70 // -> effet mais à revoir
eststo: quietly reg DeathsAfter1000confirmed30d Ind70, robust
estadd local Controls "Non"
eststo: quietly reg DeathsAfter1000confirmed30d Ind70 $controls, robust
esttab using "30d/regIndiv7030j.doc", replace p(4) scalars("Controls Contrôles") r2(4) ar2(4) drop(*$controls) mlabel("Morts20j" "Morts20j")

eststo clear

reg DeathsAfter1000confirmed30d Ind70 DemocracyindexEIU $controls, robust
reg DeathsAfter1000confirmed30d Ind70##c.DemocracyindexEIU $controls, robust

eststo: quietly reg lnDeath Ind70, robust
estadd local Controls "Non"
eststo: quietly reg lnDeath Ind70 $controls, robust
estadd local Controls "Oui"
esttab using "30d/regLnIndiv7030j.doc", replace p(4) scalars("Controls Contrôles") r2(4) ar2(4) drop(*$controls) mlabel("log(Morts20j)" "log(Morts20j)")

eststo clear

///////////////////////////////////////////
// Regression utiles pour nos résultats //
/////////////////////////////////////////

// Génération des effets d'interactions //

gen effetInteractionInd60DemoIndex = Ind60*DemocracyindexEIU
gen effetInteractionInd70DemoIndex = Ind70*DemocracyindexEIU
gen effetInteractionInd80DemoIndex = Ind80*DemocracyindexEIU

eststo: quietly reg MortsPerHabitant IndexCollecidv, robust
estadd local Controls "Non"
eststo: quietly reg MortsPerHabitant DemocracyindexEIU, robust
estadd local Controls "Non"
eststo: quietly reg MortsPerHabitant IndexCollecidv $controls, robust
estadd local Controls "Oui"
eststo: quietly reg MortsPerHabitant DemocracyindexEIU $controls, robust
estadd local Controls "Oui"
esttab using "30d/regVarContinue.tex", replace p(4) scalars("Controls Contrôles") r2(4) ar2(4) drop(*$controls)

eststo clear

eststo: quietly reg MortsPerHabitant Ind60, robust
estadd local Controls "Non"
eststo: quietly reg MortsPerHabitant Ind70, robust
estadd local Controls "Non"
eststo: quietly reg MortsPerHabitant Ind80, robust
estadd local Controls "Non"
esttab using "30d/regMortPerHabIndiv20jSansControle.tex", replace p(4) scalars("Controls Contrôles") r2(4) ar2(4)

eststo clear

eststo: quietly reg MortsPerHabitant Ind60 $controls, robust
estadd local Controls "Oui"
eststo: quietly reg MortsPerHabitant Ind70 $controls, robust
estadd local Controls "Oui"
eststo: quietly reg MortsPerHabitant Ind80 $controls, robust
estadd local Controls "Oui"

esttab using "30d/regMortPerHabIndiv20jAvecControle.tex", replace p(4) scalars("Controls Contrôles") r2(4) ar2(4) drop(*$controls)
eststo clear

// Regression pour les effets d'interactions //
eststo: quietly reg MortsPerHabitant effetInteractionInd60DemoIndex $controls, robust
estadd local Controls "Oui"
eststo: quietly reg MortsPerHabitant effetInteractionInd70DemoIndex $controls, robust
estadd local Controls "Oui"
eststo: quietly reg MortsPerHabitant effetInteractionInd80DemoIndex $controls, robust
estadd local Controls "Oui"
esttab using "30d/regInteractions20j.tex", replace p(4) scalars("Controls Contrôles") r2(4) ar2(4) drop(*$controls)

eststo clear


