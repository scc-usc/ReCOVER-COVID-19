import React, { Component } from "react";
import Covid19Predict from "./covid19predict";
import AboutUS from "./aboutus";
import ScorePage from './scorePage/scorePage';
import {BrowserRouter as Router, Route, Redirect, Switch} from 'react-router-dom'; 
import Navbar from "./navbar/navbar";
import 'semantic-ui-css/semantic.min.css';
import "./covid19app.css";

class Covid19App extends Component {
  constructor(props){
    super(props);
    this.state = {
      redirectForecast: false,
      redirectAbout: false,
      redirectScore: false
    }
  }

  redirectForecast = ()=>{
    this.setState({
      redirectForecast:true,
      redirectAbout: false,
      redirectScore: false
    });
  }

  redirectAbout = ()=>{
    this.setState({
      redirectForecast: false,
      redirectAbout:true,
      redirectScore: false
    });
  }

  redirectScore = ()=>{
    this.setState({
      redirectForecast: false,
      redirectAbout:false,
      redirectScore: true
    });
  }

  render() {
    const {redirectForecast, redirectAbout, redirectScore} = this.state;
    return (
      <Router>
        {redirectForecast?<Redirect to="/ReCOVER-COVID-19"/>:null}
        {redirectAbout?<Redirect to="/ReCOVER-COVID-19/about"/>:null}
        {redirectScore?<Redirect to="/ReCOVER-COVID-19/score"/>:null}
        <Navbar redirectForecast = {this.redirectForecast}
                redirectAbout = {this.redirectAbout}
                redirectScore = {this.redirectScore}
        />
        <Switch>
          <Route exact path='/ReCOVER-COVID-19' 
            render={(props) => <Covid19Predict {...props} />}/>
          <Route exact path='/ReCOVER-COVID-19/about'
            render={(props) => <AboutUS {...props} />} />
          <Route exact path='/ReCOVER-COVID-19/score' 
            render={(props) => <ScorePage {...props}/>}
          />
          {/* need a page for instruction */}
        </Switch>
      </Router>
    );
  }
}

export default Covid19App;
