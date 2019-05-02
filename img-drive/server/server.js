const express = require('express');
const path = require('path');
const fs = require('fs');
const morgan = require('morgan');
const multer = require('multer');
const directoryPath = path.join(__dirname, '../uploads/images');
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, directoryPath);
  },
  filename: function (req, file, cb) {
    let extArray = file.mimetype.split('/');
    let extension = extArray[extArray.length - 1];
    cb(null, file.fieldname + '-' + Date.now() + '.' + extension);
  }
});
const upload = multer({ storage: storage });
const app = express();
const PORT = 8080;

app.use(morgan('dev'));
app.use(express.json());
app.use(express.static('./client'));
app.use(express.static('./uploads'));

// upload file. currently uploading to a directory
// replace with uploading to a DB later
app.post('/upload', upload.single('photo'), (req, res) => {
  if (req.file) {
    res.json(req.file);
  }
});

// sends back an array with all the image ids
app.get('/images', (req, res) => {
  fs.readdir(directoryPath, (err, files) => {
    if (err) {
      return res.json([]);
    }
    return res.json(files);
  });
});

// eslint-disable-next-line no-console
app.listen(PORT, () => console.log(`Server up on PORT ${PORT}`));
