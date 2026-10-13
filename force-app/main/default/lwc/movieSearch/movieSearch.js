import { LightningElement, wire } from 'lwc';
// Import message service features required for publishing and the message channel
import { publish, MessageContext } from "lightning/messageService";
import movieChannel from "@salesforce/messageChannel/movieChannel__c";

const DELAY = 300;

export default class MovieSearch extends LightningElement {
    selectedType = '';
    loading = false;
    selectedSearch = '';
    selectedPageNo = 1;
    timeOut;
    searchResults = [];
    selectedMovieId = '';

    @wire(MessageContext)
    messageContext;

    get typeOptions() {
        return [
            {
                value: "",
                label: "None"
            },
            {
                value: "movie",
                label: "Movie"
            },
            {
                value: "series",
                label: "Series"
            },
            {
                value: "episode",
                label: "Episode"
            },
        ];
    }

    handleChange(event) {
        let { name, value } = event.target;

        if (name === 'type') {
            this.selectedType = value;
        }
        else if (name === 'search') {
            this.selectedSearch = value;
        }
        else if (name === 'pageno') {
            this.selectedPageNo = value;
        }
        // debounsing
        clearTimeout(this.timeOut);
        this.timeOut = setTimeout(() => {
            this.searchMovie();
        }, DELAY);

    }

    async searchMovie() {
        this.loading = true;

        // https://www.omdbapi.com/?s=Batman&page=2&apikey=e56bca9
        const url = `https://www.omdbapi.com/?s=${this.selectedSearch}&page=${this.selectedPageNo}&type=${this.selectedType}&apikey=e56bca9`;

        try {
            const res = await fetch(url);
            const data = await res.json();
            console.log('movie search output', data);

            if (data.Response === 'True') {
                this.searchResults = data.Search;
            }
        }
        catch (error) {
            console.error('Error fetching movies:', error);
        }
        finally {
            this.loading = false;
        }
    }

    get displayResult() {
        return this.searchResults.length > 0 ? true : false;
    }

    movieSelectedHandler(event) {
        this.selectedMovieId = event.detail;

        const payload = { movieId: this.selectedMovieId };

        publish(this.messageContext, movieChannel, payload);
    }
}