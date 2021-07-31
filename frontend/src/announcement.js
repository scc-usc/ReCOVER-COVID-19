import React, { Component } from "react";
import "./aboutus.css";
import "./covid19app.css";
import ReactGA from "react-ga";

class Announcements extends Component {

    componentDidMount(){
        ReactGA.initialize('UA-186385643-1');
        ReactGA.pageview('/ReCOVER/announcement');
    }

    render() {
        return (
            <div className="page-wrapper">
                <div className="article">
                    <h1 className="article-title">Paid Opportunities in COVID-19 Long-term Scenario Projections</h1>

                    <p className="article-paragraph">
                        <b>Date</b>: July 30th, 2021.
                    </p>    
                    <p className="article-paragraph">
                        <b>Contact</b>: Ajitesh Srivastava, Research Assitant Professor at the University of Southern California, email: ajiteshs AT usc DOT edu 
                    </p>

                    <p className="article-paragraph">
                       Prof Ajitesh Srivastava is seeking students to fill in multiple student-worker and research assistant positions to assist him in a project on 
                       COIVD-19 scenario projection. The project involves studying the long-term impacts of vaccines, variants, and waning immunity on COVID-19 cases, 
                       deaths, and hospitalizations. This project is a part of the US Scenario Modeling Hub that produces long-term scenario projections and communicates 
                       them to various stakeholders, including the CDC, the White House, and the WHO. Depending on the students’ interests and skills, they may work on 
                       the research challenges, implementation, and/or web design for dissemination of results. </p>
                    
                    <p className="article-paragraph"> The project may involve the following skills: 
                    </p>
                    <ol className="article-paragraph">
                    <li>   Data Science: Regression, parameter estimation, general machine learning </li>
                    <li>  Mathematics: Basics of probability, optimization, and calculus </li>
                    <li> Tools: MATLAB, Python, web-design (javascript, ReactJS, etc.) </li>
                    </ol>
                
                    <p className="article-paragraph">
                    Interested candidates must demonstrate that they can cover some of the skills stated above. 
                    Please send the following to ajiteshs AT usc DOT edu: (1) CV (2) A short description of any prior projects demonstrating the skills mentioned above 
                    (3) Availability (hours/week) during Fall 2021.
                    </p>

                </div>
            </div>

        );
    }
}

export default Announcements;