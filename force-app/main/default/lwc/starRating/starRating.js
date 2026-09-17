import { api, LightningElement } from 'lwc';
import fivestar from '@salesforce/resourceUrl/fivestar';
import {loadStyle, loadScript} from 'lightning/platformResourceLoader';

export default class StarRating extends LightningElement {
    @api value = 0;
    @api maxValue;
    @api readOnly = false;

    isRendered = false;

    renderedCallback()
    {
        if(this.isRendered) return;

        this.loadScriptAndStyle();
        this.isRendered = true;
    }

    loadScriptAndStyle()
    {
        Promise.all([
            loadScript(this, fivestar+'/rating.js'),
            loadStyle(this, fivestar+'/rating.css')
        ])
        .then(() =>{
            this.afterScriptsLoaded();
        })
        .catch((error)=>{
             // This logs the message, the full error stack, or fallback text if completely empty
            console.error('Error message: ', error.message || error.body?.message || error);
            console.error('Full Error Stack: ', error.stack);
        });
    }

    get starClass(){
        return this.readOnly ? 'readonly c-rating' : 'c-rating';
    }

    afterScriptsLoaded()
    {
        if (this.ratingObj) {
            return;
        }

        const domEl = this.template.querySelector('ul');

        // Safety check: Ensure the element is rendered in DOM before passing to library
        if (!domEl) {
            return;
        }

        const callback = (rating) =>{
            this.value = rating;

            let myEvent = new CustomEvent('ratingchange',{
                detail:{
                    rating:rating
                }
            });

            this.dispatchEvent(myEvent);
        };

       this.ratingObj = window.rating(domEl,this.value,this.maxValue,callback,this.readOnly); 
    }
}