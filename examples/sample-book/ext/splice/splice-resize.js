const bodyEl = document.body;
bodyEl.style.background = 'red';

const growBtn = document.createElement('button');
growBtn.textContent = 'Grow';
document.currentScript.parentElement.appendChild(growBtn);

growBtn.addEventListener('click', () => {
  const currentHeight = bodyEl.clientHeight;
  const newHeight = currentHeight + 100;
  bodyEl.style.height = `${newHeight}px`;
  window.parent.postMessage(
    {
      subject: 'lti.frameResize',
      height: newHeight,
    },
    '*'
  )
});