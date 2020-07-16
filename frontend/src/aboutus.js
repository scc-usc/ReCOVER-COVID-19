import React, { Component } from "react";
import "./aboutus.css";
import "./covid19app.css";

class AboutUs extends Component {
    render() {
        return (
            <div className="page-wrapper">
                <div className="article">
                    <h1 className="article-title">ReCOVER: Accurate Predictions and Resource Management for COVID-19 Epidemic Response</h1>
                    <p className="article-paragraph">
                        Accurate forecasts of COVID-19 is central to resource management and building strategies to deal with the epidemic. 
                        This is an NSF-funded project on COVID-19 forecasting led by
                        by <a className="article-anchor" href="https://sites.usc.edu/prasanna/"> Viktor K. Prasanna </a> and <a className="article-anchor" href="http://www-scf.usc.edu/~ajiteshs/"> Ajitesh Srivastava </a> 
                        from the <a className="article-anchor" href="https://dslab.usc.edu/"> Data Science Lab </a> at the University of Southern California. 
                    </p>
                    <h2>Our Approach</h2>
                    <p className="article-paragraph">
                        We use our own epidemic model called <a className="article-anchor" href="https://arxiv.org/abs/2007.05180"> SI-kJalpha</a>, preliminary version of which we have successfully used 
                        during <a className="article-anchor" href="https://news.usc.edu/83180/usc-engineers-earn-national-recognition-for-predicting-disease-outbreaks/" target="_blank">
                            DARPA Grand Challenge 2014
                        </a>.   
                        Our forecast appears on the official <a className="article-anchor" href="https://www.cdc.gov/coronavirus/2019-ncov/covid-data/forecasting-us.html"> CDC webpage</a>.
			 Our model can consider the effect of many complexities of the epidemic process and yet be simplified to a few parameters that are learned using fast linear regressions. Therefore, our approach can learn and generate forecasts extremely quickly. On a 2 core desktop machine, our approach takes only 3.18s to tune hyper-parameters, learn parameters and generate 100 days of forecasts of reported cases and deaths for all the states in the US. The total execution time for 184 countries is 11.83s and for more than 3000 US counties is 101.03s. Despite being fast, the accuracy of our forecasts is on par with the state-of-the-art as demonstrated on the <a className="article-anchor" href="https://scc-usc.github.io/ReCOVER-COVID-19/#/leaderboard"> leaderboard page</a>. Details of modeling and comparisons can be found in <a className="article-anchor" href="https://arxiv.org/abs/2007.05180"> our paper</a>.
                        This work is supported by National Science Foundation Award No. 2027007 (RAPID)
                    </p>

                    <p className="article-paragraph">
                        The <a className="article-anchor" href="https://github.com/scc-usc/ReCOVER-COVID-19" target="_blank"> Github repository </a> for this project is publicly available.
                    </p>
                    <p className="article-paragraph">
                        The matlab code for forecasting is also made available on <a className="article-anchor" href="https://www.mathworks.com/matlabcentral/fileexchange/75281-recover" target="_blank">File Exchange</a>. For the latest code, please see the Github repo.
                    </p>

			<p className="article-paragraph"> The code of the prediction model and this web application is contributed by Ajitesh Srivastava, Jamin Chen, Frost Tianjian Xu,  and Bob Xiaochen Yang. </p>
                    
                    <h2>Related Papers</h2>

                    <ol className="article-paragraph">
			<li>
                            Ajitesh Srivastava, Tianjian Xu and Viktor K. Prasanna, 
                            <a className="article-anchor" href="https://arxiv.org/abs/2007.05180" target="_blank"> "Fast and Accurate Forecasting of COVID-19 Deaths using the SIkJalpha Model"</a> [arXiv].
                        </li>
                        <li>
                            Ajitesh Srivastava and Viktor K. Prasanna, 
                            <a className="article-anchor" href="https://arxiv.org/abs/2006.02127" target="_blank"> "Data-driven Identification of Number of Unreported Cases for COVID-19: Bounds and Limitations"</a> [arXiv].
                        </li>
                        <li>
                            Ajitesh Srivastava and Viktor K. Prasanna, 
                            <a className="article-anchor" href="https://arxiv.org/abs/2004.11372" target="_blank"> "Learning to Forecast and Forecasting to Learn from the COVID-19 Pandemic"</a> [arXiv]. Accepted at KDD 2020.
                        </li>

                    </ol>
			<h2>Other Links</h2>
                    <ol className="article-paragraph">
                        <li>
                        <a className="article-anchor" href="https://www.youtube.com/watch?v=ll6k8wlxOFo" target="_blank">Webinar </a> describing our intial approach.
                    </li></ol>

			
                    <h2>USC Data Science Lab</h2>
                    <p className="article-paragraph">
                        The USC Data Science Lab focuses on applying machine learning, data mining, 
                        and network analysis to real-world problems in society and industry. 
                        Please find more information and other research projects <a className="article-anchor" href="https://sites.usc.edu/dslab/" target="_blank"> on 
                        our website</a>.
                    </p>

                </div>
            </div>

        );
    }
}

export default AboutUs;