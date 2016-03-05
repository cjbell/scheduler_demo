import React, { Component } from 'react';

const Timeslot = ({time, available, selected, onClick}) => {
  let classes = ['timeslot'];

  if (selected) { classes.push('is-selected'); }
  if (!available) { classes.push('is-disabled'); }

  return (
    <button onClick={onClick} className={classes.join(' ')}>
      {time}
    </button>
  );
};

export default Timeslot;
