document.getElementById('uploadButton').addEventListener('click', async () => {
    const fileInput = document.getElementById('resumeInput');
    const statusText = document.getElementById('status');
  
    if (!fileInput || !fileInput.files.length) {
      statusText.textContent = 'Please select a file.';
      return;
    }
  
    const file = fileInput.files[0];
    const formData = new FormData();
    formData.append('resume', file);
  
    try {
      const response = await fetch(`http://localhost:8080/upload`, {
        method: 'POST',
        body: formData
      });
  
      if (!response.ok) {
        throw new Error(`Server error: ${response.statusText}`);
      }
  
      const text = await response.text();
      let data;
  
      try {
        data = JSON.parse(text);
      } catch {
        throw new Error(`Failed to parse JSON: ${text}`);
      }
  
      console.log('Data received:', data);
  
      if (typeof chrome !== 'undefined' && chrome.storage) {
        chrome.storage.local.set({ resumeData: data }, () => {
          console.log('Stored in Chrome storage:', data);
          statusText.textContent = 'Resume uploaded and data saved!';
        });
      } else {
        localStorage.setItem('resumeData', JSON.stringify(data));
        statusText.textContent = 'Resume uploaded and data saved!';
      }
    } catch (error) {
      console.error('Upload failed:', error);
      statusText.textContent = `Error: ${error.message}`;
    }
  });
