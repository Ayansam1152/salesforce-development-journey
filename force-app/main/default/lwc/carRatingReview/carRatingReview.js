import { api, LightningElement, wire } from 'lwc';
import getCarReviews from '@salesforce/apex/CarReviewController.getCarReviews';

export default class CarRatingReview extends LightningElement {
    @api recordId
    reviews = [];
    ratingDistribution = {};
    totalReviews = 0;
    averageRating = 0;
    error;

    @wire(getCarReviews,{
        carId:'$recordId'
    })
    wiredReviews({data, error}){
        if(data)
        {
            this.reviews = data.reviews;
            this.ratingDistribution = data.ratingDistribution;
            this.totalReviews = data.totalReviews;
            this.averageRating = data.averageRating;
            this.processReviews();
        }
        else if(error)
        {
            this.error = error;
            this.reviews = null;
        }
    }

    processReviews(){
        this.reviews = this.reviews.map((review)=>{
            return {
                ...review,
                CreatedDate : this.formatDate(review.CreatedDate)
            };
        });
    }

    formatDate(dateString){
        const date = new Date(dateString);

        return date.toLocaleDateString('en-US',{
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    }

    get ratingDistributionList(){
        const distribution = [];
        for(let i = 5; i > 0; i--)
        {
            const count = this.ratingDistribution[i];
            const totalReview = this.totalReviews;
            const percentage = (count/totalReview)*100;
            const fixedPercentage = percentage.toFixed(2);

            let ratingDistributionObj = {
                rating:i,
                count:count,
                percentage:fixedPercentage
            };

            distribution.push(ratingDistributionObj);
        }

        return distribution;
    }
}