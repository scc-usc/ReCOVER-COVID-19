import React, { Component } from "react";
import Covid19Predict from "./covid19predict";

import "./covid19app.css";

class Covid19App extends Component {
  render() {
    return (
      <div className="app-wrapper">
        <Covid19Predict />
      </div>
    );
  }
}

export default Covid19App;
