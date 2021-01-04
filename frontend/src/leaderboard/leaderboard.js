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
	                     We evaluate the submissions that are made publicly on various forecasting hubs and highlight where our submissions stand.
	                     Note that the following only compares the submissions and not the forecasting methodologies.
	                     The submissions may have used different methodologies over time and tuned manually. The evaluation 
	                     of different methodologies is a part of our other upcoming project <a href="https://github.com/scc-usc/covid19-forecast-bench">here</a>.
	                     </p>
	                     <p>
	                     We are currently contributing to the following hubs. Please select one to see the evaluations.
	                     {"\n"}
	                     </p>
	                     </div>
	                     
	                     <div>
                  		<Button onClick={()=>this.setState({which_hub : USFH})}>
						US Forecast Hub                  
                  		</Button>
                  		<Button onClick={()=>this.setState({which_hub : GFH})}>
						Germany/Poland Forecast Hub                  
                  		</Button>
                      <Button onClick = {()=> openInNewTab('https://covidcompare.io/model_performance')}>
                      Country-level Evaulation by "covidcompare.io"
                    </Button>
                		</div>
                    </Row> 
                    <Row>
                    	<Iframe url={this.state.which_hub}
                    	width="100%"
        				height={(0.7*this.state.height).toString()}
        				/>
                    </Row>

                </div>
            </div>
        );
    }
}

export default Leaderboard;