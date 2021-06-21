import React, { Component } from "react";
import { List, Avatar, Row, Col } from 'antd';
import Iframe from 'react-iframe';
import "../covid19app.css";
import "./leaderboard.css";
import { Button } from "antd";
import ReactGA from "react-ga";

const GFH = "https://htmlpreview.github.io/?https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/frontend/src/leaderboard/GFH_compare.html";
const USFH = "https://htmlpreview.github.io/?https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/frontend/src/leaderboard/USFH_compare.html";
const blank_html_page = "<html></html>";

class Leaderboard extends Component {


	constructor() {
		super();
		this.state = {
			which_hub: USFH,
			width: 0, 
			height: 0,
			};
  			this.updateWindowDimensions = this.updateWindowDimensions.bind(this);
	}

	componentDidMount() {
  		this.updateWindowDimensions();
  		window.addEventListener('resize', this.updateWindowDimensions);
      ReactGA.initialize('UA-186385643-1');
      ReactGA.pageview('/ReCOVER/evaluation');
	}

	componentWillUnmount() {
  		window.removeEventListener('resize', this.updateWindowDimensions);
	}

	updateWindowDimensions() {
  		this.setState({ width: window.innerWidth, height: window.innerHeight });
	}

    getAvatar(number) {
        let icon_src = "";
        switch (number) {
            case 1:
                icon_src = "https://img.icons8.com/officel/80/000000/medal2.png";
                break;
            case 2:
                icon_src = "https://img.icons8.com/officel/80/000000/medal-second-place.png";
                break;
            case 3:
                icon_src = "https://img.icons8.com/officel/80/000000/medal2-third-place.png";
                break;
            default:
                icon_src = "https://img.icons8.com/carbon-copy/100/000000/" + number + "-circle.png";
                break;
        }

        return <Avatar className="rank-number" src={icon_src} alt="" />;

    };


    render() {
        const openInNewTab = (url) => {
  const newWindow = window.open(url, '_blank', 'noopener,noreferrer')
  if (newWindow) newWindow.opener = null
}

        return (
            <div className="page-wrapper">
                <div className="grid">
                    <Row>
	                     <div className = "introduction"><p>
	                     For our evaluation of different methodologies please see our benchmarking project here: 
	                     <Button type="default" onClick={()=> openInNewTab('https://scc-usc.github.io/covid19-forecast-bench/#/')}>
            COVID-19 Forecast Benchmarking               
                      </Button>
                       </p>
	                     <p>
	                     We participate in several forecast hubs and public evaluations. To view the evaluations produced by others, please click on one of the following buttons.
	                     {"\n"}
	                     </p>
	                     </div>
	                     
                    </Row>

                    <Row>
                    <br/>
	                     <div className = "introduction">
                  		<Button type="default" onClick={()=> openInNewTab('https://delphi.cmu.edu/forecast-eval/')}>
						US Forecast Hub                  
                  		</Button><br/>
                  		<Button type="default" onClick={()=> openInNewTab('https://jobrac.shinyapps.io/app_evaluation/')}>
						Germany/Poland Forecast Hub                  
                  		</Button><br/>
                      <Button type="default" onClick={()=> openInNewTab('https://covid19forecasthub.eu/reports')}>
            Europe Forecast Hub                  
                      </Button><br/>
                      <Button type="default" onClick = {()=> openInNewTab('https://covidcompare.io/model_performance')}>
                      Country-level Evaulation by "covidcompare.io"
                    </Button>
                		</div>
                    </Row> 
                </div>
            </div>
        );
    }
}

export default Leaderboard;