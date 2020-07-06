import React, { Component } from "react";
import {
    red,
    gold,
    lime,
    cyan,
    geekblue,
    purple,
    magenta
  } from "@ant-design/colors";

import { 
    LineChart, 
    Line,
    CartesianGrid,
    XAxis,
    YAxis,
    Tooltip,
    Legend,
    Label
} from 'recharts';

function getLineColor(index) {
    const colors = [
        red,
        gold,
        lime,
        cyan,
        geekblue,
        purple,
        magenta
    ];

    return colors[index % colors.length];
}



class NewScoreGraph extends Component {
    parseData = (data) => { 
        const firstArea = Object.keys(data)[0];
        if (data[firstArea])
        {
            const chartData = data[firstArea].observed.map((value,idx) => {
                let date = value.date.split("-")[1] + "/" + value.date.split("-")[2]
                let dataSet = {name: date};
                dataSet[Object.keys(data)[0]] = value.value;
                for (let i = 1; i < Object.keys(data).length; ++i)
                {
                    dataSet[Object.keys(data)[i]] = data[Object.keys(data)[i]].observed[idx].value
                }
                return dataSet
            });

            return chartData;
        }
    }
    
    render(){
        let {data} = this.props;
        //map data
        const chartData = this.parseData(data);
        console.log(chartData);
        //areas and line color
        const areas = Object.keys(data);
        console.log(areas);
        let colors = [];
        areas.map((area, idx)=>{
            let strokeColor = getLineColor(idx);
            colors.push(strokeColor[3]);
            return 0;
        });
        console.log(colors);
        let lines = [];
        for (let i = 0; i < areas.length; ++i)
        {
            lines.push(<Line type="monotone" key={i} dataKey={areas[i]} stroke={colors[i]} strokeWidth={5} />)
        }
        return(
            <LineChart width={1400} height={300} data={chartData}
            margin={{ top: 40, right: 30, left: 40, bottom: 5 }}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" />
            <YAxis>
                <Label value="Dynamic Reproduction Number" dy = {90} position="insideLeft" angle={-90} fontSize={15} />
            </YAxis>
            <Tooltip />
            <Legend iconSize={40}/>
            {lines}
            </LineChart>
        );
    }
}

export default NewScoreGraph;

  