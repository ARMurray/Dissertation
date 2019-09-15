# Dissertation Outline

## Estimating Vulnerability to Privately Owned Domestic Wells in Response to Extreme Precipitation Events

### Chapter 1: the relationship between soil moisture, precipitation and Landcover

Driving questions: 
* Can we predict what the SMAP soil moisture reading will be before it happens?
* Do soil moisture values respond to Hurricanes in predictable ways based on landcover?

Data Products to be Used:
* SMAP 9km soil moisture
* PRISM daily rainfall
* 2016 NLCD

Analyses:
* Extract NLCD values to SMAP pixels using dominant landcover type. I think dominant landcover should be used here but perhaps I need to extract all landcover types and their percent coverage.
* Using SMAP soil moisture products, make every pixel an outlet and delineate it's watershed.
Calculate percentages of Landcover types in that watershed
Create metrics of precipitation such as: 
+ total PPT within previous 7 days of soil moisture capture.
Create a topography metric which will provide steepness of the watershed
Calculate dominant soil type in the watershed
Establish relationship between soil moisture and calculated variables

Chapter 2: SMAP assisted estimation of hydraulic conductivity, recharge, and water table height.

Hypothesis: High frequency soil moisture readings can tell us how quickly the soil is becoming saturated or drying out. With known soil data, PPT data and elevation data we can use soil moisture to estimate rates of recharge, conductivity and water table depth.

Would likely need to collect well drilling records to establish baseline water table levels through time.
Could also incorporate USGS monitoring wells though these are sparse.
Incorporate EPA published infiltration models

Chapter 3: DRASTIC+

Hypothesis: the DRASTIC index can be improved by incorporating SMAP assisted recharge, conductivity and water table depth. It can be further benefited by incorporating land cover and topography.
Using established DRASTIC variables along with methods established in chapter 1 & 2, the DRASTIC+ index can be calculated every 1.5 days (when a new SMAP capture becomes available)
This index will be a 30m raster, corresponding to the data it uses with the finest resolution (NLCD & SSURGO).

Chapter 4: Performance of DRASTIC+ in response to extreme precipitation events

Hypothesis: Higher rates of well contamination will occur in areas estimated to be more vulnerable.
Well testing records will be sought from labs at Virginia Tech, Texas A&M, NC State and from within UNC. Collectively, these groups have conducted water well testing immediately following the past five major hurricanes to hit the southeastern US (Matthew, Harvey, Irma, Michael, Florence).

Chapter 5: Automating DRASTIC+ to run in a standalone or web based environment and deployment for public use

This is largely dependent on where funding comes from over the next year or two.
Could be incorporated into existing programs such as SpoRT at NASA or could simply self automate the method at UNC and deploy results on personal website.
A long term goal of mine which probably is outside the scope of this dissertation is to create a DRASTIC+ visualization tool online that also acts as a place where the public can self-report the existence of private wells and water testing results.

Larry band model

Make sure you look at existing models so I don’t reinvent the wheel.


