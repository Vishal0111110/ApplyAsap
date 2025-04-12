console.log("content.js is running!");

function getResumeData(callback) {
    chrome.storage.local.get("resumeData", (data) => {
        console.log("Retrieved Resume Data:", data);

        if (!data || !data.resumeData) {
            console.error("No resume data found in storage.");
            return;
        }

        callback(data.resumeData);
    });
}

function fillForm(resumeData) {
    if (!resumeData || !resumeData.personalDetails) {
        console.error("Missing personal details in resume.");
        return;
    }

    function updateField(field, value) {
        if (field && value) {
            console.log(`Updating: ${field.name || field.id || field.placeholder} with value: ${value}`);
            field.focus();
            field.value = value;
            field.dispatchEvent(new Event("input", { bubbles: true }));
            field.dispatchEvent(new Event("change", { bubbles: true }));
        }
    }

    const fields = document.querySelectorAll("input, textarea, select");
    console.log("Found form fields:", fields.length);

    fields.forEach(field => {
        let fieldName = (field.name || field.id || field.placeholder || "").toLowerCase();
        let value = "";

        if (fieldName.includes("name")) value = resumeData.personalDetails.name || "";
        if (fieldName.includes("email")) value = resumeData.personalDetails.email || "";
        if (fieldName.includes("phone")) value = resumeData.personalDetails.phone || "";
        if (fieldName.includes("linkedin")) value = "https://www.linkedin.com/in/"+resumeData.personalDetails.social_media.github || "";
        if (fieldName.includes("github")) value = "https://github.com/"+resumeData.personalDetails.social_media.twitter || "";
        if (fieldName.includes("address")) value = resumeData.personalDetails.address || "";
        if (fieldName.includes("city") || fieldName.includes("location")) value = resumeData.personalDetails.city || "";
        if (fieldName.includes("state")) value = resumeData.personalDetails.state || "";
        if (fieldName.includes("zip")) value = resumeData.personalDetails.zip || "";
        if (fieldName.includes("information") || fieldName.includes("additionalinformation")) value = resumeData.coverLetter || "";

        if (value) {
            updateField(field, value);
        }
    });

    console.log("Autofill completed.");
}

function observeAndFillForm() {
    console.log("Waiting for form fields...");

    const observer = new MutationObserver((mutations, obs) => {
        const formFields = document.querySelectorAll("input, textarea, select");
        if (formFields.length > 0) {
            console.log(` Form fields detected: ${formFields.length}, attempting autofill...`);
            getResumeData(fillForm);
            obs.disconnect(); 
        }
    });

    observer.observe(document.body, { childList: true, subtree: true });

    setTimeout(() => {
        if (document.querySelector("input, textarea, select")) {
            console.log("Checking form fields after timeout...");
            getResumeData(fillForm);
        }
    }, 3000);
}

document.addEventListener("DOMContentLoaded", observeAndFillForm);
setTimeout(observeAndFillForm, 3000);
