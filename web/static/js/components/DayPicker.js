import React, { Component } from 'react';

const DayPicker = ({day, selected, onClick}) => (
  <button onClick={onClick} className={selected ? 'is-selected' : ''}>
    {day}
  </button>
);

export default DayPicker;
