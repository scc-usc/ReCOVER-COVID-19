import React, { Component } from "react";
import Covid19Predict from "./covid19predict";
import AboutUS from "./aboutus";
import ScorePage from './scorePage/scorePage';
import {BrowserRouter as HashRouter, Route, Redirect, Switch} from 'react-router-dom'; 
import Navbar from "./navbar/navbar";
import 'semantic-ui-css/semantic.min.css';
import "./covid19app.css";
import Leaderboard from "./leaderboard/leaderboard";

class Covid19App extends Component {
  constructor(props){
    super(props);
    this.state = {
      redirectForecast: false,
      redirectAbout: false,
      redirectScore: false,
      redirectLeaderboard: false
    }
  }

  redirectForecast = ()=>{
    this.setState({
      redirectForecast:true,
      redirectAbout: false,
      redirectScore: false,
      redirectLeaderboard: false
    });
  }

  redirectAbout = ()=>{
    this.setState({
      redirectForecast: false,
      redirectAbout:true,
      redirectScore: false,
      redirectLeaderboard: false
    });
  }

  redirectScore = ()=>{
    this.setState({
      redirectForecast: false,
      redirectAbout:false,
      redirectScore: true,
      redirectLeaderboard: false
    });
  }

  redirectLeaderboard = ()=>{
    this.setState({
      redirectForecast: false,
      redirectAbout: false,
      redirectScore: false,
      redirectLeaderboard: true
    });
  }

  render() {
    const {redirectForecast, redirectAbout, redirectScore, redirectLeaderboard} = this.state;
    return (
      <HashRouter>
        {redirectForecast?<Redirect to="/ReCOVER-COVID-19"/>:null}
        {redirectScore?<Redirect to="/ReCOVER-COVID-19/score"/>:null}
        {redirectAbout?<Redirect to="/ReCOVER-COVID-19/about"/>:null}
        {redirectLeaderboard?<Redirect to="/ReCOVER-COVID-19/leaderboard"/>:null}
        <Navbar redirectForecast = {this.redirectForecast}
                redirectScore = {this.redirectScore}
                redirectAbout = {this.redirectAbout}
                redirectLeaderboard = {this.redirectLeaderboard}
        />
        <Switch>
          <Route exact path='/ReCOVER-COVID-19' 
            render={(props) => <Covid19Predict {...props} />}/>
          <Route exact path='/ReCOVER-COVID-19/score' 
            render={(props) => <ScorePage {...props}/>}
          />
          <Route exact path='/ReCOVER-COVID-19/about'
            render={(props) => <AboutUS {...props} />} />
          <Route exact path='/ReCOVER-COVID-19/leaderboard' 
            render={(props) => <Leaderboard {...props} />}/>
          
          {/* need a page for instruction */}
        </Switch>
      </HashRouter>
    );
  }
}

export default Covid19App;
