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
    image.classList.add('gallery-img');

    preview.appendChild(image);
  }
}

function fetchImages (){
  fetch('/images')
    .then(res => res.json())
    .then(res => {
      res.forEach(image => {
        const div = document.createElement('div');
        const img = document.createElement('img');
        img.src = `/images/${image}`;
        img.classList.add('gallery-img');
        div.appendChild(img);
        gallery.appendChild(div);
      });
    });
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
    .then(fetchImages());
}

const preview = document.querySelector('.preview');
const input = document.querySelector('input');
const form = document.querySelector('form');
const gallery = document.querySelector('#gallery');

input.addEventListener('change', updateImageDisplay);
form.addEventListener('submit', submitImage);

if (gallery) {
  fetchImages();
}