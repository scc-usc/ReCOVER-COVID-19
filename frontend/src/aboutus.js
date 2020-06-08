import React, { Component } from "react";
import {
    Layout,
    Row,
    Col,
} from 'antd';
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
                        This is a NSF-funded project on COVID-19 forecasting directed 
                        by Viktor K. Prasanna (<a className="article-anchor" href="mailto:prasanna@usc.edu">prasanna@usc.edu</a>) and
                        Ajitesh Srivastava (<a className="article-anchor" href="mailto:ajiteshs@usc.edu">ajiteshs@usc.edu</a>) 
                        from the Data Science Lab in the University of Southern California. 
                    </p>
                    <h2>Our Model</h2>
                    <p className="article-paragraph">
                        We use our own epidemic model called SI-kJalpha -- Heterogeneous Infection Rate with Human Mobility, which is a 
                        preliminary version of what we have successfully used 
                        during <a className="article-anchor" href="https://news.usc.edu/83180/usc-engineers-earn-national-recognition-for-predicting-disease-outbreaks/" target="_blank">
                            DARPA Grand Challenge 2014
                        </a>.  
                        By linearizing the model and using weighted least squares, 
                        our model is able to quickly adapt to changing trends and provide extremely accurate predictions of confirmed cases 
                        at the level of countries and states of the United States. Training the model to forecast also enables learning characteristics 
                        of the epidemic. In particular, we have shown that changes in model parameters over time can help us quantify how well a state 
                        or a country has responded to the epidemic. The variations in parameters also allow us to forecast different scenarios such as 
                        what would happen if we were to disregard social distancing suggestions. 
                        This work is supported by National Science Foundation Award No. 2027007 (RAPID)
                    </p>
                    <p className="article-paragraph">
                        Details of our initial approach can be found in our <a className="article-anchor" href="https://www.youtube.com/watch?v=ll6k8wlxOFo" target="_blank">webinar</a>.
                    </p>
                    <p className="article-paragraph">
                        The Github repository for this project is <a className="article-anchor" href="https://github.com/scc-usc/ReCOVER-COVID-19" target="_blank">publicly available</a> .
                    </p>
                    <p className="article-paragraph">
                        The matlab code for forecasting is also made available on <a className="article-anchor" href="https://www.mathworks.com/matlabcentral/fileexchange/75281-recover" target="_blank">File Exchange</a>.
                    </p>
                    <p className="article-paragraph">
                        The code of the prediction model and this web application is contributed by Ajitesh Srivastava, Jamin Chen, and Frost Tianjian Xu.
                    </p>
                    <h2>USC Data Science Lab</h2>
                    <p className="article-paragraph">
                        The USC Data Science Lab focuses on applying machine learning, data mining, 
                        and network analysis to real-world problems in society and industry. 
                        Please find more information and other research projects <a className="article-anchor" href="https://sites.usc.edu/dslab/" target="_blank"> on 
                        our website</a>.
                    </p>
                    <h2>Related Publications</h2>
                    <p className="disclaimer">
                        <b>Disclaimer:</b> The following papers may have copyright restrictions. Downloads will have to adhere to these restrictions. 
                        They may not be reposted without explicit permission from the copyright holder. Any opinions, findings, and conclusions or 
                        recommendations expressed in these materials are those of the author(s) and do not necessarily reflect the views of the sponsors 
                        including National Science Foundation (NSF), Defense Advanced Research Projects Agency (DARPA), and any other sponsors listed in 
                        the publications.
                    </p>
                    <ol className="article-paragraph">
                        <li>
                            Ajitesh Srivastava and Viktor K. Prasanna, 
                            <a className="article-anchor" href="https://arxiv.org/abs/2004.11372" target="_blank"> “Learning to Forecast and Forecasting to Learn from the COVID-19 Pandemic”</a> [arXiv].
                        </li>
                    </ol>


                    




                </div>
            </div>

        );
    }
}

export default AboutUs;