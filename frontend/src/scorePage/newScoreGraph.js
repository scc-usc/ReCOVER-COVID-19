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
    Label,
    ErrorBar
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
                dataSet[`error${Object.keys(data)[0]}`] = value.conf;
                for (let i = 1; i < Object.keys(data).length; ++i)
                {
                    dataSet[Object.keys(data)[i]] = data[Object.keys(data)[i]].observed[idx].value;
                    dataSet[`error${Object.keys(data)[i]}`] = data[Object.keys(data)[i]].observed[idx].conf;
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
        //areas and line color
        const areas = Object.keys(data);
        let colors = [];
        areas.map((area, idx)=>{
            let strokeColor = getLineColor(idx);
            colors.push(strokeColor);
            return 0;
        });
        let lines = [];
        for (let i = 0; i < areas.length; ++i)
        {
            lines.push(
                <Line type="monotone" key={i} dataKey={areas[i]} stroke={colors[i][3]} strokeWidth={5}>
                    <ErrorBar dataKey={`error${areas[i]}`} width={15} strokeWidth={2} stroke={colors[i][6]} direction="y" />
                </Line>
            )
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

  