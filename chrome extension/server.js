const express = require('express');
const multer = require('multer');
const AutofillWithResume = require('autofill-with-resume');
const fs = require('fs');
const path = require('path');
const cors = require('cors');
const dotenv = require('dotenv');
dotenv.config();

const app = express();
app.use(cors({
    origin: '*',
    methods: ['POST', 'GET'],
    allowedHeaders: ['Content-Type']
  }));
  const upload = multer({ dest: 'uploads/' });

const API_KEY = process.env.API_KEY ;

app.post('/upload', upload.single('resume'), (req, res) => {
  const filePath = req.file.path;

  const processor = new AutofillWithResume(API_KEY, filePath);

  processor.extractResumeDetails()
    .then(details => {
    // console.log("Resume details:", details);
      res.json(details);
      fs.unlinkSync(filePath); 
    })
    .catch(error => {
      console.error("Error processing resume:", error);
      res.status(500).json({ error: "Error processing resume" });
      fs.unlinkSync(filePath); 
      // Clean up the uploaded file
    });
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
