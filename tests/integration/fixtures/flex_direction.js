it('flex_direction', () => {
  function setStyle(dom, object) {
    for (let key in object) {
      if (object.hasOwnProperty(key)) {
        dom.style[key] = object[key];
      }
    }
  }

  document.body.appendChild(document.createTextNode('flex-direction row'));
  const container = document.createElement('div');
  setStyle(container, {
    width: '200px',
    height: '100px',
    display: 'flex',
    backgroundColor: '#666',
    flexDirection: 'row',
  });

  document.body.appendChild(container);

  const child1 = document.createElement('div');
  setStyle(child1, {
    width: '50px',
    height: '50px',
    backgroundColor: 'blue',
  });
  container.appendChild(child1);

  const child2 = document.createElement('div');
  setStyle(child2, {
    width: '50px',
    height: '50px',
    backgroundColor: 'red',
  });
  container.appendChild(child2);

  document.body.appendChild(document.createTextNode('flex-direction column'));
  const container2 = document.createElement('div');
  setStyle(container2, {
    width: '200px',
    height: '100px',
    display: 'flex',
    backgroundColor: '#666',
    flexDirection: 'column',
  });

  document.body.appendChild(container2);

  const child3 = document.createElement('div');
  setStyle(child3, {
    width: '50px',
    height: '50px',
    backgroundColor: 'blue',
  });
  container2.appendChild(child3);

  const child4 = document.createElement('div');
  setStyle(child4, {
    width: '50px',
    height: '50px',
    backgroundColor: 'red',
  });
  container2.appendChild(child4);
});