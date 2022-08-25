import React, { Component } from "react";
import "./aboutus.css";
import "./covid19app.css";
import ReactGA from "react-ga";

class AboutUs extends Component {

    componentDidMount(){
        ReactGA.initialize('UA-186385643-1');
        ReactGA.pageview('/ReCOVER/about');
    }

    render() {
        return (
            <div className="page-wrapper">
                <div className="article">
                    <h1 className="article-title">ReCOVER: Accurate Predictions and Scenario Projections for COVID-19 Epidemic Response</h1>
                        
                    <p className="article-paragraph">
                        <b>Contact</b>: Ajitesh Srivastava, Research Assitant Professor at the University of Southern California, email: ajiteshs AT usc DOT edu 
                    </p>

                    <h2>Our Approach</h2>
                    <p className="article-paragraph">
                        We use our own epidemic model called <a className="article-anchor" href="https://arxiv.org/abs/2207.02919"> SI-kJalpha</a>, preliminary version of which we have successfully used 
                        during <a className="article-anchor" href="https://news.usc.edu/83180/usc-engineers-earn-national-recognition-for-predicting-disease-outbreaks/" target="_blank">
                            DARPA Grand Challenge 2014
                        </a>.   
                        Our forecast appears on the official <a className="article-anchor" href="https://www.cdc.gov/coronavirus/2019-ncov/covid-data/forecasting-us.html" target="_blank"> CDC webpage</a>.
			             Our model can consider the effect of many complexities of the epidemic process and yet be simplified to a few parameters that are learned using fast linear regressions. 
                         Therefore, our approach can learn and generate forecasts extremely quickly. On a 2 core desktop machine, our approach takes only 3.18s to tune hyper-parameters, 
                         learn parameters and generate 100 days of forecasts of reported cases and deaths for all the states in the US. The total execution time for 184 countries is 11.83s and 
                         for more than 3000 US counties is around 25s. Despite being fast, the accuracy of our forecasts is on par with the state-of-the-art as demonstrated on the 
                        <a className="article-anchor" href="https://scc-usc.github.io/ReCOVER-COVID-19/#/leaderboard"> leaderboard page</a>. 
                    Details of initial modeling and comparisons can be found in <a className="article-anchor" href="https://arxiv.org/abs/2007.05180" target="_blank"> our paper</a>. Since writing of this paper, additional
                    capabilities have been included in the model. Currently, the model accounts for vaccinations and all variants as per <a className="article-anchor" href="https://outbreak.info" target="_blank">
                     outbreak.info</a>. 
                    </p>

                    <p className="article-paragraph">
                        The <a className="article-anchor" href="https://github.com/scc-usc/ReCOVER-COVID-19" target="_blank"> Github repository </a> for this project is publicly available.
                    </p>
                    

        			<p className="article-paragraph"> The code of the prediction model is written by Ajitesh Srivastava. </p>
                    
        			<p className="article-paragraph"> The forecast visualization is created by Ajitesh Srivastava and Frost Tianjian Xu with the assistance from Jamin Chen, Bob Xiaochen Yang, James Orme-Rogers, James Wolfe, Sung Bin Kim, and Vicky Yu. </p>


                    <h2> Acknowledgements </h2>

                    <p className="article-paragraph"> This work is supported by National Science Foundation Award No. 2027007 (2020-2021) and Award No. 2135784 (2021-2022) </p>

                    <h2>Related Papers</h2>

                    <ol className="article-paragraph">
                    <li>
                    Ajitesh Srivastava, <a className="article-anchor" href="https://arxiv.org/abs/2207.02919" target="_blank"> "The Variations of SIkJalpha Model for COVID-19 Forecasting and Scenario Projections"</a> [arXiv].
                    </li>
                    <li>
                            Rebecca et. al., 
                            <a className="article-anchor" href="https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8118153/" target="_blank"> 
                            "Modeling of Future COVID-19 Cases, Hospitalizations, and Deaths, by Vaccination Rates and Nonpharmaceutical Intervention Scenarios — United States, April–September 2021"</a> 
                            MMWR. Morbidity and mortality weekly report vol. 70,19 719-724. 14 May. 2021.
                        </li>
			             <li>
                            Ajitesh Srivastava, Tianjian Xu and Viktor K. Prasanna, 
                            <a className="article-anchor" href="https://arxiv.org/abs/2007.05180" target="_blank"> "Fast and Accurate Forecasting of COVID-19 Deaths using the SIkJalpha Model"</a> [arXiv].
                        </li>
                        <li>
                            Ajitesh Srivastava and Viktor K. Prasanna, 
                            <a className="article-anchor" href="https://arxiv.org/abs/2006.02127" target="_blank"> "Data-driven Identification of Number of Unreported Cases for COVID-19: Bounds and Limitations"</a> [arXiv]. Accepted at KDD 2020.
                        </li>
                        <li>
                            Ajitesh Srivastava and Viktor K. Prasanna, 
                            <a className="article-anchor" href="https://arxiv.org/abs/2004.11372" target="_blank"> "Learning to Forecast and Forecasting to Learn from the COVID-19 Pandemic"</a> [arXiv]. 
                        </li>

                    </ol>
			<h2>Other Links</h2>
                    <ol className="article-paragraph">
                    <li>
                        <a className="article-anchor" href="https://www.youtube.com/watch?v=dBye3euqlKc" target="_blank"> Lightning talk </a> presenting the status (October).
                    </li>
                        <li>
                        <a className="article-anchor" href="https://www.youtube.com/watch?v=ll6k8wlxOFo" target="_blank">Webinar </a> describing our intial approach (April).
                    </li></ol>


                </div>
            </div>

        );
    }
}

export default AboutUs;