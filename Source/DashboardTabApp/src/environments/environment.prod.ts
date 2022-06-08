export const environment = {
    production: false,
    apiBaseUrl: "https://qbotoztrial.azurewebsites.net/api/Request/",

    authConfig: {
        instance: "https://login.microsoftonline.com/",
        tenantId: "feb72289-50bd-4466-88dd-21b68087b583",
        clientId: "6e562469-32fe-403c-858f-67b2bea333a3",
        redirectUri: "/app-silent-end",
        cacheLocation: "localStorage",
        navigateToLoginRequestUrl: false,
        extraQueryParameters: "",
        popUp: true,
        popUpUri: "/app-silent-start",
        popUpWidth: 600,
        popUpHeight: 535
    },

    // do not populate the following:
    upn: "",
    tid: "",
};
