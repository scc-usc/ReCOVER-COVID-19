import React, { Component } from "react";

import {
    Menu,
    Row,
    Col
} from 'antd';
import "./navbar.css";
import 'bootstrap/dist/css/bootstrap.min.css';
import { Navbar, Nav, NavDropdown } from 'react-bootstrap'


// class NavBar extends Component {
const NavBar = () => {
    return (
        <Navbar collapseOnSelect expand="lg" bg="dark" variant="dark">
          <Navbar.Brand href="#/"><img
                    className="logo"
                    src="https://identity.usc.edu/files/2011/12/combo_gold_white_cardinal.png"
                    alt="USC"
                /></Navbar.Brand>
          <Navbar.Toggle aria-controls="responsive-navbar-nav" />
          <Navbar.Collapse id="responsive-navbar-nav">
            <Nav className="mr-auto">
              <Nav.Link href="#/">COVID-19 Forecast</Nav.Link>
              <Nav.Link href="#score">Reproduction Number</Nav.Link>
              <Nav.Link href="#highlights">Highlights</Nav.Link>
              <Nav.Link href="#leaderboard">Leaderboard</Nav.Link>
              <Nav.Link href="#about">About Us</Nav.Link>
            </Nav>
            <Nav>
            </Nav>
          </Navbar.Collapse>
        </Navbar>
    )
}
export default NavBar;