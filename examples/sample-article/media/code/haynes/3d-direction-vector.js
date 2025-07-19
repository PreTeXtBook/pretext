var listeners = function(ggb) {

    const tbody1 = document.getElementById('ggb_2__17_table1').getElementsByTagName('tbody')[0];
    const a_to_b = document.getElementById('a_to_b');  // buttons
    const b_to_a = document.getElementById('b_to_a');

// update html (slate) when diagram changes
function coordinates(){
    return [[], xyz('A'), xyz('B')]
}

function cell(r,c) {
    tbody1.getElementsByTagName('tr')[r].getElementsByTagName('td')[c].innerHTML= coordinates()[r][c];
};

function xyz(obj){
   return [[], ggb.getXcoord(obj).toFixed(0), ggb.getYcoord(obj).toFixed(0),  ggb.getZcoord(obj).toFixed(0)]
};


var updateSlate = function (){
    for (let i = 1; i < 3; i++) {
        for(let j=1; j < 4; j++)
        cell(i,j)
      }

  // GGB booleans decide what to show, only one allowed at a time.;
  info = document.getElementById('info');
   if (ggb.getValue('showAB')==true) {
        info.innerHTML = "\\["  +  ggb.getValueString('textAB') + "\\] \\["  +  ggb.getValueString('textABhat') + "\\]" ;
  }

  if (ggb.getValue('showBA')==true) {
       info.innerHTML =  "\\[ " +  ggb.getValueString('textBA') +  "\\] \\["  +  ggb.getValueString('textBAhat') + "\\]";
  }

  if (window.MathJax) {
     MathJax.typesetPromise([info]).then(() => {});
  }
}

a_to_b.addEventListener('click',function () { ggb.evalCommand('RunClickScript(atob)' )});
b_to_a.addEventListener('click',function () { ggb.evalCommand('RunClickScript(btoa)' )});
ggb.registerUpdateListener(updateSlate);

updateSlate();
tbody1.getElementsByTagName('tr')[1].style.color='red';
tbody1.getElementsByTagName('tr')[2].style.color='blue';

}
