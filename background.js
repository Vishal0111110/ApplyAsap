chrome.runtime.onInstalled.addListener(() => {
  console.log("Extension installed");
});

chrome.runtime.onMessageExternal.addListener((message, sender, sendResponse) => {
  if (message.type === "getResumeData") {
      chrome.storage.local.get("resumeData", (result) => {
          sendResponse(result.resumeData);
      });
      return true;
  }
});

chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.status === "complete") {
      chrome.scripting.executeScript({
          target: { tabId: tabId },
          files: ["content.js"]
      }).then(() => console.log("Injected content.js into:", tab.url));
  }
});

chrome.webNavigation.onCompleted.addListener((details) => {
  chrome.scripting.executeScript({
      target: { tabId: details.tabId },
      files: ["content.js"]
  });
});

