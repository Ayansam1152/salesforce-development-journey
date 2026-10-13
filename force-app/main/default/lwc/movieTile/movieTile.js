import { LightningElement, api } from 'lwc';

export default class MovieTile extends LightningElement {
    @api movie;
    @api selectedMovie;

    clickHandler(event) {
        const selectedEvent = new CustomEvent('movieselected', {
            detail: this.movie.imdbID
        });

        this.dispatchEvent(selectedEvent);
    }

    get tileSelected()
    {
        return this.selectedMovie === this.movie.imdbID ? 'tile selected' : 'tile';
    }
}