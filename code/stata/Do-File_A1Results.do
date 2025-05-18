* Jorge
*cd "/Users/jorgearmandoruedagallardo/Library/CloudStorage/OneDrive-Bibliotecascompartidas:UniversidadEAFIT/VP - 2025_WB_LatinAmerica/02_Sampling/Databases/output"

* Laura
cd "C:/Users/user/OneDrive - Universidad EAFIT/2025_WB_LatinAmerica/02_Sampling/Databases/output"
 

local direccion "SILAS_IPC_foodsecurity_departamental_2021 mean_hazards"

foreach x in `direccion'{
	import excel "`x'.xlsx", firstrow allstring clear
	save "`x'.dta", replace 
	}

local direccion "ACLEC_Numero_eventos_departamental_2023  ACLED_Numero_eventos_departamental_tot ACLEC_Numero_fatalities_departamental_2023 WRI_fragility_departamental ACLED_Numero_fatalities_departamental_tot"
local i=1	
	foreach x in `direccion'{
		import delimited "`x'.csv", stringcols(_all) clear 
		replace base_datos=base_datos+"_"+"`i'"
		save "`x'.dta", replace 
		local i=`i'+1
	}

	

	use "SILAS_IPC_foodsecurity_departamental_2021.dta", clear
	
	local direccion "ACLEC_Numero_eventos_departamental_2023 ACLEC_Numero_fatalities_departamental_2023 WRI_fragility_departamental ACLED_Numero_eventos_departamental_tot ACLED_Numero_fatalities_departamental_tot mean_hazards"
	
	foreach x in `direccion'{
		append using "`x'.dta"
	}
	

	drop  tipodecálculo tipoinformación Tipodecálculo Tipoinformación
	
	drop if base_datos==""
	
	
	destring valor, replace
	
	for var pais departamento municipio: replace X=upper(X)
	
		replace departamento=subinstr(departamento,"á","A", .)
		replace departamento=subinstr(departamento,"é","E", .)
		replace departamento=subinstr(departamento,"ó","O", .)
		replace departamento=subinstr(departamento,"ñ","N", .)
		replace departamento=subinstr(departamento,"í","I", .)
		replace departamento=trim(departamento)
		
		replace departamento="QUETZALTENANGO" if departamento=="QUEZALTENANGO"
		replace departamento="PETEN" if departamento=="EL PETEN"
		replace departamento="SACATEPEQUEZ" if departamento=="SACATEPENQUEZ"
		replace departamento="SUCHITEPEQUEZ" if departamento=="SUCHITPEQUEZ"
		replace departamento="ATLANTICO NORTE" if departamento=="COSTA CARIBE NORTE"
		replace departamento="ATLANTICO SUR" if departamento=="COSTA CARIBE SUR"
		replace base_datos="UNODC" if base_datos=="DATA_UNOC"
		replace id_pais = "GTM" if id_pais == "" & pais == "GUATEMALA"
		replace departamento = "ISLAS DE BAHIA" if departamento == "ISLAS DE LA BAHIA"
	
***Información a nivel departamental***
		
		replace id_nivel = "3" if id_nivel == "2"

  		
	
		gen id=pais+"-"+departamento
		gen tiempo=base_datos+"-"+dimension+"-"+id_indicador
		
		for var id tiempo: encode X, gen(X_num)
		
		xtset id_num tiempo_num
		
		tsfill, full
		
		local VARIABLE "id_num tiempo_num"
		foreach x in `VARIABLE' {
			sdecode  `x', gen(`x'_1)
			drop `x'
			rename `x'_1 `x'
		}
		
		split id_num, p(-)
		split tiempo_num, p(-)
		
		replace pais=id_num1 if pais==""
		replace departamento=id_num2 if departamento==""
		replace base_datos=tiempo_num1 if base_datos==""
		replace dimension=tiempo_num2 if dimension==""
		replace id_indicador=tiempo_num3 if id_indicador==""
		
		drop id_num* tiempo* id
				
		replace valor=0 if valor==.
		
		sort dimension base_datos id_indicador indicador pais departamento
		order dimension base_datos id_indicador indicador pais departamento
	
	gsort dimension base_datos id_indicador -indicador
	
	
	bys dimension base_datos id_indicador: replace indicador=indicador[_n-1] if indicador==""
	
	
	bys dimension base_datos id_indicador : egen max=max(valor)
	bys dimension base_datos id_indicador : egen min=min(valor)
	bys dimension base_datos id_indicador : egen desv=sd(valor)

	
	gen normalizado=1-(max-valor)/(max-min)
	
	
	
preserve
drop if (departamento == "ZELAYA CENTRAL" | departamento == "BAY ISLANDS" | departamento == "DISTRITO CENTRAL")
replace pais = "SALVADOR" if pais == "EL SALVADOR"
save "variables_general.dta", replace 
restore	


* Por dimension	
* Food securiy
preserve
keep if id_indicador == "12"
save "Depto_priorizado_foodsecurity.dta", replace 
restore


* Result - dimension using PCA (Fragility and violence & Conflict)
tab dimension
replace dimension = "Food" if dimension =="Food security"
replace dimension =  "Violence" if dimension == "Violence & Conflict"

* We use only some variables for violence, while we use the entire dataset for fragility

local dimension "Fragility  Violence"

foreach a in `dimension' {
    preserve
* Var for ACLEC   
drop if id_indicador == "ACLEC _3_3_1" | id_indicador == "ACLEC _3_3_2" | id_indicador == "ACLEC _3_3_3" | id_indicador == "ACLEC _3_3_4" | id_indicador == "ACLEC _3_3_5" | id_indicador == "ACLEC _3_3_6" | id_indicador == "ACLEC _3_3_7" | id_indicador == "ACLEC _3_3_8" | id_indicador == "ACLEC _3_3_5_tot" | id_indicador == "ACLEC _3_3_6_tot" | id_indicador == "ACLEC _3_3_7_tot" | id_indicador == "ACLEC _3_3_8_tot"

* Var for fragility 
* Variables sin adaptacion al cambio climatico
*drop if id_indicador == "hazards_2_2_1" | id_indicador == "hazards_2_2_2" | id_indicador == "hazards_2_2_4" | id_indicador == "hazards_2_2_5" | id_indicador == "hazards_2_2_6" | id_indicador == "hazards_2_2_8"

drop if id_indicador == "WRI_2_2_1" | id_indicador == "WRI_2_2_2" | id_indicador == "WRI_2_2_3" | id_indicador == "WRI_2_2_4" | id_indicador == "hazards_2_2_3" | id_indicador == "hazards_2_2_7"



	keep if dimension == "`a'"
    encode dimension, gen(dim)
    encode base_datos, gen(base)
    encode id_indicador, gen(id_ind)
    gen intento = "A_" + string(dim) + "_" + string(base) + "_" + string(id_ind)
    keep normalizado intento pais departamento
    reshape wide normalizado, i(pais departamento) j(intento, string)

    replace pais = "SALVADOR" if pais == "EL SALVADOR"

    foreach var of varlist * {
        capture assert missing(`var')
        if _rc == 0 {
            drop `var'
        }
    }

    ds pais departamento, not
    local vars ""
    foreach var of varlist `r(varlist)' {
        capture confirm numeric variable `var'
        if !_rc local vars `vars' `var'
    }

    pca `vars'

    scalar suma = 0
    local comp = e(trace)
    forval j = 1/`comp' {
        scalar suma = suma + e(Ev)[1, `j']
        scalar suma_`j' = suma
    }

    scalar lim = 0.81
    forval j = 1/`comp' {
        scalar prop_acum_`j' = suma_`j' / suma
        scalar a_`j' = (prop_acum_`j' < lim)
    }

    predict pc1 pc2 pc3 pc4 

    foreach var of varlist pc1 pc2 pc3 pc4  {
        sum `var'
        gen `var'_minmax = 1 - ((r(max) - `var') / (r(max) - r(min)))
    }

   gen puntaje= pc1_minmax*a_1*e(Ev)[1,1]+pc2_minmax*a_2*e(Ev)[1,2]+pc3_minmax*a_3*e(Ev)[1,3]+pc4_minmax*a_4*e(Ev)[1,4]
   
   sum puntaje
   gen puntaje_minmax_`a' = 1 - ((r(max) - puntaje) / (r(max) - r(min)))
   
   
    keep pais departamento puntaje_minmax_`a'
    save "priorizacion_A11`a'.dta", replace
    restore
}


* Laura - Poblacion 

cd "C:/Users/user/OneDrive - Universidad EAFIT/2025_WB_LatinAmerica/02_Sampling/Databases/data_orig/Landscan"
import excel "landscan_data.xlsx", firstrow allstring clear

rename (NAME_0 NAME_1) (pais departamento) 
for var pais departamento: replace X = upper(X)
		replace departamento=subinstr(departamento,"á","A", .)
		replace departamento=subinstr(departamento,"é","E", .)
		replace departamento=subinstr(departamento,"ó","O", .)
		replace departamento=subinstr(departamento,"ñ","N", .)
		replace departamento=subinstr(departamento,"í","I", .)
		
		
replace departamento = "ISLAS DE BAHIA" if departamento == "ISLAS DE LA BAHIA"

destring poblacion, replace		


save "poblacion.dta", replace


clear 


cd "C:/Users/user/OneDrive - Universidad EAFIT/2025_WB_LatinAmerica/02_Sampling/Databases/output"

use  "priorizacion_A11Fragility.dta"
mmerge pais departamento using "priorizacion_A11Violence.dta"

drop if (departamento == "ZELAYA CENTRAL" | departamento == "BAY ISLANDS" | departamento == "DISTRITO CENTRAL")


forvalues i = 2(1) 5 {

for var puntaje_minmax_Fragility puntaje_minmax_Violence: xtile X_`i' = X, n(`i')
gen cat_`i'     = "high - high" if (puntaje_minmax_Fragility_`i' == `i' & puntaje_minmax_Violence_`i' == `i')
replace cat_`i' = "high - low"    if (puntaje_minmax_Fragility_`i' == `i' & puntaje_minmax_Violence_`i' != `i')
replace cat_`i' = "low - high"    if (puntaje_minmax_Fragility_`i' != `i' & puntaje_minmax_Violence_`i' == `i')
replace cat_`i' = "low - low"     if (puntaje_minmax_Fragility_`i' != `i' & puntaje_minmax_Violence_`i' != `i')
} 



replace pais = "EL SALVADOR" if pais == "SALVADOR" 

preserve
keep pais departamento puntaje_minmax_Fragility puntaje_minmax_Violence cat_*
save "temporalA11.dta", replace
restore

preserve
use "variables_general.dta", clear
keep pais departamento indicador valor normalizado
replace pais = "EL SALVADOR" if pais == "SALVADOR" 
mmerge pais departamento using "temporalA11.dta"
mmerge pais departamento using "C:/Users/user/OneDrive - Universidad EAFIT/2025_WB_LatinAmerica/02_Sampling/Databases/data_orig/Landscan/poblacion.dta", ukeep(poblacion)
format valor normalizado puntaje_minmax_Fragility puntaje_minmax_Violence  %9.2f
drop _merge
order pais departamento indicador valor normalizado puntaje_minmax_Fragility puntaje_minmax_Violence poblacion
rename (pais departamento indicador valor normalizado puntaje_minmax_Fragility puntaje_minmax_Violence poblacion) (country state indicator value value_norm value_fragility value_violence population)
drop if indicator == "Fatalities - Protests"
save "variables_general_categoria.dta",replace
export excel "variables_general_categoriaA11.xlsx", firstrow(variable) replace
restore

mmerge pais departamento using "Depto_priorizado_foodsecurity.dta", ukeep(normalizado valor)
rename (normalizado valor) (food_normalizad food_valor)
drop if (departamento == "ZELAYA CENTRAL" | departamento == "BAY ISLANDS" | departamento == "DISTRITO CENTRAL")
mmerge pais departamento using "C:/Users/user/OneDrive - Universidad EAFIT/2025_WB_LatinAmerica/02_Sampling/Databases/data_orig/Landscan/poblacion.dta", ukeep(poblacion)


export excel "variablesA11.xls", firstrow(variable) replace
rename (food_normalizad food_valor) (normalizado valor) 
bys cat_4: sum valor
bys cat_3: sum valor
bys cat_2: sum valor