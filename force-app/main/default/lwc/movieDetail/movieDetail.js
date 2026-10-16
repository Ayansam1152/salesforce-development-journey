import { LightningElement, wire } from 'lwc';
// Import message service features required for subscribing and the message channel
import {
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext,
} from "lightning/messageService";
import movieChannel from "@salesforce/messageChannel/movieChannel__c";

export default class MovieDetail extends LightningElement {
    subscribe = null;
    loading = false;
    movieDetails = {};

    @wire(MessageContext)
    messageContext;

    // Handler for message received by component
    handleMessage(message) {
        let movieId = message.movieId;
        console.log('movieId', movieId);

        this.fetchMovieDetails(movieId);
    }

    // Standard lifecycle hooks used to subscribe and unsubsubscribe to the message channel
    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }


    // Encapsulate logic for Lightning message service subscribe and unsubsubscribe
    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                movieChannel,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE },
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    async fetchMovieDetails(movieId) {
        // http://www.omdbapi.com/?i=tt5950044&plot=full
        const url = `https://www.omdbapi.com/?i=${movieId}&plot=full&apikey=e56bca9`;

        try {
            const res = await fetch(url);
            const data = await res.json();
            this.movieDetails = data;

            console.log('movie details', data);
        }
        catch (error) {
            console.log('error while fetching movie', error);
        }
        finally {
            this.loading = true;
        }
    }

}