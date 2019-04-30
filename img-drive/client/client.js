function updateImageDisplay () {
  // If there is something inside preview, remove it.
  while (preview.firstChild) {
    preview.removeChild(preview.firstChild);
  }

  // Get current files.
  const curFiles = input.files;

  // If no files selected, show paragraph, otherwise, show image preview
  if (!curFiles.length) {
    const para = document.createElement('p');
    para.textContent = 'No files currently selected for upload';
    preview.appendChild(para);
  } else {
    const image = document.createElement('img');
    image.src = window.URL.createObjectURL(curFiles[0]);

    preview.appendChild(image);
  }
}

function submitImage (e) {
  e.preventDefault();
  const curFiles = input.files;
  const formData = new FormData();
  formData.append('photo', curFiles[0]);

  fetch('/upload', {
    method: 'POST',
    body: formData
  })
    .then(res => console.log(res));
}

const preview = document.querySelector('.preview');
const input = document.querySelector('input');
const form = document.querySelector('form');

input.addEventListener('change', updateImageDisplay);
form.addEventListener('submit', submitImage);